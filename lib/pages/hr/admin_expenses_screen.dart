// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/expense_provider.dart';
import 'package:mpg_hr_mobile_app/services/expense_repository.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';

class AdminExpensesScreen extends ConsumerStatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  ConsumerState<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends ConsumerState<AdminExpensesScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.expenseClaimsTitle,
          style: const TextStyle(color: AppColors.grey800, fontSize: 18, fontWeight: FontWeight.w700),
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
      body: Column(
        children: [
          // Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppColors.grey500),
                const SizedBox(width: 8),
                ...['all', 'pending', 'approved', 'rejected', 'paid'].map((status) {
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
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.grey100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.grey500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: expensesAsync.when(
              data: (items) {
                final filtered = _statusFilter == 'all' ? items : items.where((e) => e.status == _statusFilter).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 64, color: AppColors.grey300.withAlpha(128)),
                        const SizedBox(height: 12),
                        Text(l10n.noExpenseClaims, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.grey500)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                      onEdit: e.status == 'pending' ? () => _showEditExpenseSheet(context, e) : null,
                      onDelete: _canDelete(e.status) ? () => _deleteExpense(e.id) : null,
                    );
                  },
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
      backgroundColor: AppColors.surfaceLight,
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
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AdminExpenseForm(onSubmitted: () => ref.invalidate(expensesProvider)),
    );
  }

  void _showEditExpenseSheet(BuildContext context, ExpenseData e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_categoryIcon(expense.category), color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      if (expense.description != null && expense.description!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(expense.description!, style: const TextStyle(fontSize: 11, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      if (expense.employeeName != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(expense.employeeName!, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                            if (expense.employeeId != null && expense.employeeId!.isNotEmpty) ...[
                              const Text(' · ', style: TextStyle(fontSize: 10, color: AppColors.grey400)),
                              Text(expense.employeeId!, style: const TextStyle(fontSize: 10, color: AppColors.grey400)),
                            ],
                          ],
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _capitalize(expense.status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'travel': return Icons.flight;
      case 'meals': return Icons.restaurant;
      case 'supplies': return Icons.inventory_2;
      case 'software': return Icons.computer;
      case 'transport': return Icons.directions_car;
      case 'accommodation': return Icons.hotel;
      case 'other':
      default: return Icons.receipt_outlined;
    }
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
              Text(l10n.expenseDetailTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow(l10n.titleLabel, expense.title),
          if (expense.employeeName != null) _detailRow(l10n.employeeLabel, expense.employeeName!),
          _detailRow(l10n.categoryLabel, expense.category),
          _detailRow(l10n.amountLabel, '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}'),
          _detailRow(l10n.expenseDateLabel, expense.date),
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
            _detailRow(l10n.descriptionLabel, expense.description!),
          ],
          if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.rejectionReasonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
            const SizedBox(height: 2),
            Text(expense.rejectionReason!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
          if (expense.paidAt != null && expense.paidAt!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(l10n.paidAtLabel, expense.paidAt!),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.grey800)),
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
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseClaimUpdatedSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      } else {
        final repo = ref.read(expenseRepositoryProvider);
        await repo.submitClaim(
          title: _titleCtrl.text.trim(),
          category: _category,
          amount: double.parse(_amountCtrl.text.trim()),
          currency: _currency,
          expenseDate: formattedDate,
          description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        );
        widget.onSubmitted();
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseClaimSubmittedSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
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
                  Text(_isEditing ? l10n.editExpenseClaimTitle : l10n.newExpenseClaimTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800)),
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
                    border: Border.all(color: AppColors.grey300),
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900),
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