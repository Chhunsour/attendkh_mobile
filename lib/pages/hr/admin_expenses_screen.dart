import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/providers/expense_provider.dart';
import 'package:attendkh/services/expense_repository.dart';
import 'package:attendkh/services/admin_operations_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:attendkh/services/network/exceptions.dart';
import 'package:attendkh/services/network/dio_client.dart';
import 'package:attendkh/components/loading_indicator.dart';

class AdminExpensesScreen extends ConsumerStatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  ConsumerState<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends ConsumerState<AdminExpensesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.expenseClaimsTitle,
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary, size: 28),
            onPressed: () => _showAddExpenseSheet(context),
            tooltip: l10n.newClaimTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(expensesProvider),
            tooltip: l10n.refreshTooltip,
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (items) {
          final pendingCount = items.where((e) => e.status == 'pending').length;
          final approvedTotal = items.where((e) => e.status == 'approved' || e.status == 'paid').fold<double>(0, (sum, e) => sum + e.amount);
          final rejectedCount = items.where((e) => e.status == 'rejected').length;

          final q = _searchQuery.trim().toLowerCase();
          final filtered = items.where((e) {
            final matchesStatus = _statusFilter == 'all' || e.status == _statusFilter;
            final matchesQuery = q.isEmpty ||
                e.title.toLowerCase().contains(q) ||
                (e.description != null && e.description!.toLowerCase().contains(q)) ||
                e.category.toLowerCase().contains(q) ||
                (e.employeeName != null && e.employeeName!.toLowerCase().contains(q)) ||
                (e.employeeCode != null && e.employeeCode!.toLowerCase().contains(q));
            return matchesStatus && matchesQuery;
          }).toList();

          return Column(
            children: [
              // ── Top KPI Summary Cards ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        value: pendingCount.toString(),
                        label: 'Pending',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _kpiCard(
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        value: '\$${approvedTotal.toStringAsFixed(approvedTotal == approvedTotal.roundToDouble() ? 0 : 2)}',
                        label: 'Approved/Paid',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _kpiCard(
                        icon: Icons.cancel_outlined,
                        color: AppColors.danger,
                        value: rejectedCount.toString(),
                        label: 'Rejected',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search & Filter Controls ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search title, employee, code...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.grey400),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['all', 'pending', 'approved', 'rejected', 'paid'].map((status) {
                          final isActive = _statusFilter == status;
                          String label;
                          switch (status) {
                            case 'all': label = l10n.filterAll; break;
                            case 'pending': label = l10n.filterPending; break;
                            case 'approved': label = l10n.filterApproved; break;
                            case 'rejected': label = l10n.filterRejected; break;
                            case 'paid': label = l10n.filterPaid; break;
                            default: label = status;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: isActive,
                              onSelected: (_) => setState(() => _statusFilter = status),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isActive ? Colors.white : AppColors.grey700,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              backgroundColor: AppColors.surfaceLight,
                              side: BorderSide(color: isActive ? AppColors.primary : AppColors.grey200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ── Claims List ──────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_outlined, size: 64, color: AppColors.grey300.withAlpha(128)),
                            const SizedBox(height: 12),
                            Text(l10n.noExpenseClaims, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.grey500)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = filtered[i];
                          final statusColor = e.status == 'approved'
                              ? AppColors.success
                              : e.status == 'rejected'
                                  ? AppColors.danger
                                  : e.status == 'paid'
                                      ? AppColors.info
                                      : AppColors.warning;
                          return _AdminExpenseCard(
                            expense: e,
                            statusColor: statusColor,
                            onTap: () => _showDetailModal(context, e, statusColor),
                            onApprove: e.status == 'pending' ? () => _approveExpense(e.id) : null,
                            onReject: e.status == 'pending' ? () => _showRejectDialog(context, e.id) : null,
                            onPay: e.status == 'approved' ? () => _markAsPaid(e.id) : null,
                            onEdit: () => _showEditExpenseSheet(context, e),
                            onDelete: _canDelete(e.status) ? () => _deleteExpense(e.id) : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => LoadingIndicator(message: l10n.loadingExpenses),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(expensesProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({required IconData icon, required Color color, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _canDelete(String status) => status == 'approved' || status == 'rejected' || status == 'paid';

  Future<void> _approveExpense(int id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await AdminOperationsRepository().approveExpense(id);
      ref.invalidate(expensesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseApprovedSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _markAsPaid(int id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await AdminOperationsRepository().markExpensePaid(id);
      ref.invalidate(expensesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseMarkedPaidSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteExpense(int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteClaimTitle),
        content: Text(l10n.deleteExpenseClaimConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteTitle, style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteExpense(id);
        ref.invalidate(expensesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.claimDeletedSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        _showError(e);
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rejectClaimTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.rejectClaimPrompt, style: const TextStyle(fontSize: 13, color: AppColors.grey600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: l10n.rejectionReasonLabel,
                  border: const OutlineInputBorder(),
                  hintText: l10n.rejectionReasonHint,
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.rejectionReasonRequired : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: Text(l10n.rejectBtn),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await AdminOperationsRepository().rejectExpense(id, reason: reasonCtrl.text.trim());
        ref.invalidate(expensesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Expense rejected'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        _showError(e);
      }
    }
  }

  void _showDetailModal(BuildContext context, ExpenseData e, Color statusColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AdminExpenseDetailSheet(
        expense: e,
        statusColor: statusColor,
        onEdit: () => _showEditExpenseSheet(context, e),
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AdminExpenseForm(onSubmitted: () => ref.invalidate(expensesProvider)),
    );
  }

  void _showEditExpenseSheet(BuildContext context, ExpenseData e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AdminExpenseForm(onSubmitted: () => ref.invalidate(expensesProvider), initial: e),
    );
  }

  void _showError(dynamic e) {
    String msg = 'Operation failed';
    if (e is AppException) msg = e.message;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// ─── Admin Expense Card ────────────────────────────────────────────────────

class _AdminExpenseCard extends StatelessWidget {
  final ExpenseData expense;
  final Color statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onPay;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AdminExpenseCard({
    required this.expense,
    required this.statusColor,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.onPay,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmployeeAvatar(
                  photoUrl: expense.employeePhoto,
                  name: expense.employeeName ?? expense.title,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              expense.employeeName ?? 'Employee',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (expense.employeeKhmerName != null &&
                              expense.employeeKhmerName!.trim().isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '(${expense.employeeKhmerName!.trim()})',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.grey500,
                                  fontWeight: FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (expense.employeeCode != null &&
                              expense.employeeCode!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                expense.employeeCode!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (expense.employeePosition != null &&
                          expense.employeePosition!.trim().isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          expense.employeePosition!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.grey500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (expense.description != null &&
                          expense.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          expense.description!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _capitalize(expense.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 58, top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(expense.category, style: const TextStyle(fontSize: 10, color: AppColors.grey500)),
                  ),
                  const SizedBox(width: 8),
                  Text(expense.date, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                  if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.attach_file, size: 12, color: AppColors.grey400),
                  ],
                ],
              ),
            ),
            if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 58, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.block, size: 12, color: AppColors.danger),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${l10n.reasonPrefix}${expense.rejectionReason!}',
                        style: const TextStyle(fontSize: 11, color: AppColors.danger, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            if (expense.paidAt != null && expense.paidAt!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 58, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 12, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text('${l10n.paidPrefix}${expense.paidAt}', style: const TextStyle(fontSize: 11, color: AppColors.info)),
                  ],
                ),
              ),
            // Action buttons
            if (expense.status == 'pending') ...[
              const SizedBox(height: 10),
              Row(children: [
                if (onEdit != null) ...[
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary), onPressed: onEdit, tooltip: l10n.editBtn),
                  const SizedBox(width: 4),
                ],
                if (onReject != null)
                  Expanded(child: OutlinedButton.icon(onPressed: onReject, icon: const Icon(Icons.close, size: 16), label: Text(l10n.rejectBtn), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)))),
                const SizedBox(width: 8),
                if (onApprove != null)
                  Expanded(child: ElevatedButton.icon(onPressed: onApprove, icon: const Icon(Icons.check, size: 16), label: Text(l10n.approve))),
              ]),
            ] else if (expense.status == 'approved') ...[
              const SizedBox(height: 10),
              Row(children: [
                if (onEdit != null) ...[
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary), onPressed: onEdit, tooltip: l10n.editBtn),
                  const SizedBox(width: 4),
                ],
                if (onPay != null)
                  Expanded(child: OutlinedButton.icon(onPressed: onPay, icon: const Icon(Icons.payment, size: 16), label: Text(l10n.markAsPaidBtn), style: OutlinedButton.styleFrom(foregroundColor: AppColors.info, side: const BorderSide(color: AppColors.info)))),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger), onPressed: onDelete, tooltip: l10n.deleteTitle),
                ],
              ]),
            ] else ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary), onPressed: onEdit, tooltip: l10n.editBtn),
                  if (onDelete != null)
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger), onPressed: onDelete, tooltip: l10n.deleteTitle),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }


  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '$currency ';
    }
  }
}

// ─── Admin Detail Sheet ────────────────────────────────────────────────────

class _AdminExpenseDetailSheet extends StatelessWidget {
  final ExpenseData expense;
  final Color statusColor;
  final VoidCallback? onEdit;

  const _AdminExpenseDetailSheet({
    required this.expense,
    required this.statusColor,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.expenseDetailTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          if (expense.employeeName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withAlpha(30)),
              ),
              child: Row(
                children: [
                  _buildEmployeeAvatar(
                    photoUrl: expense.employeePhoto,
                    name: expense.employeeName!,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                expense.employeeName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (expense.employeeKhmerName != null &&
                                expense.employeeKhmerName!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '(${expense.employeeKhmerName!})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (expense.employeeCode != null &&
                                expense.employeeCode!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  expense.employeeCode!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            if (expense.employeePosition != null &&
                                expense.employeePosition!.isNotEmpty) ...[
                              if (expense.employeeCode != null)
                                const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  expense.employeePosition!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.grey600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _detailRow(context, l10n.titleLabel, expense.title),
          _detailRow(context, l10n.categoryLabel, expense.category),
          _detailRow(context, l10n.amountLabel, '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}'),
          _detailRow(context, l10n.expenseDateLabel, expense.date),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.statusPrefix, style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _capitalize(expense.status),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          if (expense.description != null && expense.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(context, l10n.descriptionLabel, expense.description!),
          ],
          if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.rejectionReasonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
            const SizedBox(height: 2),
            Text(expense.rejectionReason!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
          if (expense.paidAt != null && expense.paidAt!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(context, l10n.paidAtLabel, expense.paidAt!),
          ],
          if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.receiptLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.description, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.receiptPath!.split('/').last,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey700),
                  ),
                ),
              ],
            ),
          ],
          if (onEdit != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEdit!();
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Expense Claim'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context))),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '$currency ';
    }
  }
}

Widget _buildEmployeeAvatar({
  String? photoUrl,
  required String name,
  double size = 32,
}) {
  final cleanName = name.trim();
  final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'E';
  final effectiveUrl = (photoUrl != null && photoUrl.isNotEmpty)
      ? (photoUrl.startsWith('http')
          ? photoUrl
          : '${DioClient.storageUrl}/${photoUrl.startsWith('/') ? photoUrl.substring(1) : photoUrl}')
      : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(cleanName.isNotEmpty ? cleanName : "Employee")}&background=4F46E5&color=fff&bold=true';

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.primary.withAlpha(20),
      border: Border.all(
        color: AppColors.primary.withAlpha(40),
        width: 1.5,
      ),
    ),
    child: ClipOval(
      child: CachedNetworkImage(
        imageUrl: effectiveUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (_, _, _) => Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    ),
  );
}

// ─── Admin Expense Form (Add/Edit) ─────────────────────────────────────────

class _AdminExpenseForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  final ExpenseData? initial;

  const _AdminExpenseForm({required this.onSubmitted, this.initial});

  @override
  ConsumerState<_AdminExpenseForm> createState() => _AdminExpenseFormState();
}

class _AdminExpenseFormState extends ConsumerState<_AdminExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Travel';
  String _currency = 'USD';
  DateTime _expenseDate = DateTime.now();
  File? _receiptFile;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.initial!;
      _titleCtrl.text = e.title;
      _category = e.category;
      _amountCtrl.text = e.amount.toString();
      _currency = e.currency;
      _descCtrl.text = e.description ?? '';
      if (e.date.isNotEmpty) {
        final parsed = DateTime.tryParse(e.date);
        if (parsed != null) _expenseDate = parsed;
      }
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _receiptFile = File(image.path));
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _expenseDate = date);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_expenseDate);

      if (_isEditing) {
        final repo = AdminOperationsRepository();
        await repo.updateExpense(widget.initial!.id, {
          'title': _titleCtrl.text.trim(),
          'category': _category,
          'amount': double.parse(_amountCtrl.text.trim()),
          'currency': _currency,
          'expense_date': formattedDate,
          if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        });
        widget.onSubmitted();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.expenseClaimUpdatedSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        final repo = ref.read(expenseRepositoryProvider);
        await repo.submitClaim(
          title: _titleCtrl.text.trim(),
          category: _category,
          amount: double.parse(_amountCtrl.text.trim()),
          currency: _currency,
          expenseDate: formattedDate,
          description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
          receipt: _receiptFile,
        );
        widget.onSubmitted();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.expenseClaimSubmittedSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${e is AppException ? e.message : e}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isEditing ? l10n.editExpenseClaimTitle : l10n.newExpenseClaimTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(labelText: l10n.titleFieldLabel, border: const OutlineInputBorder(), hintText: l10n.titleHint),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.titleRequired : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l10n.categoryFieldLabel, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'Travel', child: Text(l10n.catTravel)),
                  DropdownMenuItem(value: 'Meals', child: Text(l10n.catMeals)),
                  DropdownMenuItem(value: 'Supplies', child: Text(l10n.catSupplies)),
                  DropdownMenuItem(value: 'Software', child: Text(l10n.catSoftware)),
                  DropdownMenuItem(value: 'Transport', child: Text(l10n.catTransport)),
                  DropdownMenuItem(value: 'Accommodation', child: Text(l10n.catAccommodation)),
                  DropdownMenuItem(value: 'Other', child: Text(l10n.catOther)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration: InputDecoration(labelText: l10n.amountFieldLabel, border: const OutlineInputBorder(), prefixText: '\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
                        if (double.tryParse(v.trim()) == null) return l10n.invalidAmount;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(labelText: l10n.currencyLabel, border: const OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _currency = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.expenseDateLabel,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE, dd MMM yyyy').format(_expenseDate),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: l10n.descriptionOptionalLabel, border: const OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Receipt (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickReceipt,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _receiptFile != null ? AppColors.primary : AppColors.grey300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _receiptFile != null ? Icons.check_circle_rounded : Icons.attach_file_rounded,
                            color: _receiptFile != null ? AppColors.success : AppColors.grey500,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _receiptFile != null ? _receiptFile!.path.split('/').last : 'Upload receipt image...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _receiptFile != null ? FontWeight.w600 : FontWeight.w400,
                                color: _receiptFile != null ? AppColors.grey900 : AppColors.grey400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_receiptFile != null)
                            GestureDetector(
                              onTap: () => setState(() => _receiptFile = null),
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? l10n.updateClaimBtn : l10n.submitClaimBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
