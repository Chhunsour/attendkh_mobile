import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/expense_provider.dart';
import 'package:mpg_hr_mobile_app/services/expense_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary, size: 28),
            onPressed: () => _showAddExpenseSheet(context, ref),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => expenses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_outlined, size: 64, color: AppColors.grey300.withAlpha(128)),
                    const SizedBox(height: 12),
                    const Text('No expense claims found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.grey500)),
                    const SizedBox(height: 4),
                    const Text('Submit your first expense claim to get started', style: TextStyle(fontSize: 12, color: AppColors.grey400)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: expenses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final e = expenses[i];
                  final statusColor = _statusColor(e.status);
                  return _ExpenseCard(
                    expense: e,
                    statusColor: statusColor,
                    onTap: () => _showDetailModal(context, e, statusColor),
                    onEdit: e.status == 'pending' ? () => _showEditExpenseSheet(context, ref, e) : null,
                    onDelete: e.status == 'pending' ? () => _deleteExpense(context, ref, e) : null,
                  );
                },
              ),
        loading: () => const LoadingIndicator(message: 'Loading expenses...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(expensesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.danger;
      case 'paid': return AppColors.info;
      case 'pending':
      default: return AppColors.warning;
    }
  }

  void _showAddExpenseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExpenseForm(onSubmitted: () => ref.invalidate(expensesProvider)),
    );
  }

  void _showEditExpenseSheet(BuildContext context, WidgetRef ref, ExpenseData e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExpenseForm(
        onSubmitted: () => ref.invalidate(expensesProvider),
        initial: e,
      ),
    );
  }

  void _showDetailModal(BuildContext context, ExpenseData e, Color statusColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExpenseDetailSheet(expense: e, statusColor: statusColor),
    );
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, ExpenseData e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Claim'),
        content: Text('Delete "${e.title}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final repo = ref.read(expenseRepositoryProvider);
        await repo.deleteClaim(e.id);
        ref.invalidate(expensesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Claim deleted'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (ex) {
        String msg = 'Failed to delete';
        if (ex is AppException) msg = ex.message;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }
}

// ─── Expense Card ──────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final ExpenseData expense;
  final Color statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ExpenseCard({required this.expense, required this.statusColor, this.onTap, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 2),
                      Text(expense.date, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
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
                  if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.info_outline, size: 14, color: AppColors.danger),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        expense.rejectionReason!,
                        style: const TextStyle(fontSize: 11, color: AppColors.danger, fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.attach_file, size: 12, color: AppColors.grey400),
                  ],
                ],
              ),
            ),
            if (expense.status == 'pending' && (onEdit != null || onDelete != null)) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    ),
                  ],
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

// ─── Detail Sheet ──────────────────────────────────────────────────────────

class _ExpenseDetailSheet extends StatelessWidget {
  final ExpenseData expense;
  final Color statusColor;

  const _ExpenseDetailSheet({required this.expense, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expense Claim Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow('Title', expense.title),
          _detailRow('Category', expense.category),
          _detailRow('Amount', '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}'),
          _detailRow('Expense Date', expense.date),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Status: ', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
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
            _detailRow('Description', expense.description!),
          ],
          if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Rejection Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
            const SizedBox(height: 2),
            Text(expense.rejectionReason!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
          if (expense.paidAt != null && expense.paidAt!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow('Paid At', expense.paidAt!),
          ],
          if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.description, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  expense.receiptPath!.split('/').last,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey700),
                ),
              ],
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

// ─── Expense Form (Add/Edit) ───────────────────────────────────────────────

class _ExpenseForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  final ExpenseData? initial;

  const _ExpenseForm({required this.onSubmitted, this.initial});

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Travel';
  String _currency = 'USD';
  DateTime _expenseDate = DateTime.now();
  File? _receipt;
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
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _expenseDate = date);
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _receipt = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_expenseDate);

      if (_isEditing) {
        final repo = ref.read(expenseRepositoryProvider);
        await repo.updateClaim(
          id: widget.initial!.id,
          title: _titleCtrl.text.trim(),
          category: _category,
          amount: double.parse(_amountCtrl.text.trim()),
          currency: _currency,
          expenseDate: formattedDate,
          description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
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
          receipt: _receipt,
        );
      }
      widget.onSubmitted();
      if (mounted) Navigator.pop(context);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? '✅ Expense claim updated' : '✅ Expense claim submitted'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      String msg = _isEditing ? 'Failed to update' : 'Failed to submit';
      if (e is AppException) msg = e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
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
                  Text(
                    _isEditing ? 'Edit Expense Claim' : 'New Expense Claim',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Client lunch, Taxi fare',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                  DropdownMenuItem(value: 'Meals', child: Text('Meals')),
                  DropdownMenuItem(value: 'Supplies', child: Text('Supplies')),
                  DropdownMenuItem(value: 'Software', child: Text('Software')),
                  DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                  DropdownMenuItem(value: 'Accommodation', child: Text('Accommodation')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
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
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
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
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expense Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_expenseDate),
                    style: const TextStyle(fontSize: 15, color: AppColors.grey800),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Receipt upload — only for new claims, matching web behavior
              if (!_isEditing) ...[
                InkWell(
                  onTap: _pickReceipt,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Receipt (optional)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.upload_file),
                    ),
                    child: Text(
                      _receipt != null
                          ? _receipt!.path.split('/').last
                          : 'Tap to select image (JPG, PNG)',
                      style: TextStyle(
                        fontSize: 13,
                        color: _receipt != null ? AppColors.grey800 : AppColors.grey400,
                      ),
                    ),
                  ),
                ),
                if (_receipt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        const Text('Receipt selected',
                            style: TextStyle(fontSize: 11, color: AppColors.success)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _receipt = null),
                          child: const Text('Remove',
                              style: TextStyle(fontSize: 11, color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Update Claim' : 'Submit Claim',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}