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
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.expenses,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(expensesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Claim Expense',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final pending = expenses.where((e) => e.status == 'pending').toList();
          final approved = expenses.where((e) => e.status == 'approved' || e.status == 'paid').toList();

          final totalPendingAmount = pending.fold<double>(0, (sum, e) => sum + e.amount);
          final totalApprovedAmount = approved.fold<double>(0, (sum, e) => sum + e.amount);

          final filtered = expenses.where((e) {
            if (_statusFilter == 'all') return true;
            return e.status.toLowerCase() == _statusFilter.toLowerCase();
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(expensesProvider),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                // ── Overview Metric Cards ──
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Claims',
                        value: '${expenses.length}',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Pending',
                        value: '\$${totalPendingAmount.toStringAsFixed(0)}',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Approved',
                        value: '\$${totalApprovedAmount.toStringAsFixed(0)}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Status Filter Chips Strip ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', expenses.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending', pending.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved', expenses.where((e) => e.status == 'approved').length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Paid', 'paid', expenses.where((e) => e.status == 'paid').length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected', expenses.where((e) => e.status == 'rejected').length),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Claims List ──
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 56, color: AppColors.grey300),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noExpenseClaims,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.grey700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.submitFirstExpense,
                            style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((e) {
                    final statusColor = _statusColor(e.status);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ExpenseCard(
                        expense: e,
                        statusColor: statusColor,
                        onTap: () => _showDetailModal(context, e, statusColor),
                        onEdit: e.status == 'pending' ? () => _showEditExpenseSheet(context, ref, e) : null,
                        onDelete: e.status == 'pending' ? () => _deleteExpense(context, ref, e) : null,
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => LoadingIndicator(message: l10n.loadingExpenses),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(expensesProvider),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.grey600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      case 'paid':
        return const Color(0xFF0EA5E9);
      case 'pending':
      default:
        return AppColors.warning;
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteClaim),
        content: Text(l10n.deleteClaimConfirm(e.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.grey600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final repo = ref.read(expenseRepositoryProvider);
        await repo.deleteClaim(e.id);
        ref.invalidate(expensesProvider);
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text(l10n.claimDeleted), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (ex) {
        String msg = l10n.failedToDelete;
        if (ex is AppException) msg = ex.message;
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_categoryIcon(expense.category), color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.grey900),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(expense.date, style: const TextStyle(fontSize: 11.5, color: AppColors.grey500)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getCategoryL10n(expense.category, l10n),
                                style: const TextStyle(fontSize: 10, color: AppColors.grey600, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.attach_file_rounded, size: 13, color: AppColors.primary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.grey900),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _capitalize(expense.status),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          expense.rejectionReason!,
                          style: const TextStyle(fontSize: 11, color: AppColors.danger),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (expense.status == 'pending' && (onEdit != null || onDelete != null)) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.grey100),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: Text(l10n.edit),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: Text(l10n.delete),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'meals':
        return Icons.restaurant_rounded;
      case 'supplies':
        return Icons.inventory_2_outlined;
      case 'software':
        return Icons.computer_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      case 'other':
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _getCategoryL10n(String category, AppLocalizations l10n) {
    switch (category.toLowerCase()) {
      case 'travel': return l10n.travel;
      case 'meals': return l10n.meals;
      case 'supplies': return l10n.supplies;
      case 'software': return l10n.software;
      case 'transport': return l10n.transport;
      case 'accommodation': return l10n.accommodation;
      case 'other':
      default: return l10n.other;
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
              Text(
                l10n.expenseClaimDetails,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.grey900),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(l10n.title, expense.title),
          _detailRow(l10n.category, expense.category),
          _detailRow(l10n.amount, '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}'),
          _detailRow(l10n.expenseDate, expense.date),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.statusLabel, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _capitalize(expense.status),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          if (expense.description != null && expense.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(l10n.description, expense.description!),
          ],
          if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.rejectionReason, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey600)),
            const SizedBox(height: 2),
            Text(expense.rejectionReason!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
          if (expense.paidAt != null && expense.paidAt!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(l10n.paidAt, expense.paidAt!),
          ],
          if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.receipt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.description, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  expense.receiptPath!.split('/').last,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey900)),
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
          ),
          child: child!,
        );
      },
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
      final compressed = await ImageCompressor.compressToJpeg(picked.path);
      setState(() => _receipt = compressed);
    }
  }

  void _removeReceipt() => setState(() => _receipt = null);

  Future<void> _submit(AppLocalizations l10n) async {
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
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? l10n.expenseClaimUpdated : l10n.expenseClaimSubmitted),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      String msg = _isEditing ? l10n.failedToUpdate : l10n.failedToSubmit;
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Expense Claim' : 'New Expense Claim',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.grey500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title / Subject *',
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),

              // Category & Currency row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                        DropdownMenuItem(value: 'Meals', child: Text('Meals')),
                        DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                        DropdownMenuItem(value: 'Supplies', child: Text('Supplies')),
                        DropdownMenuItem(value: 'Software', child: Text('Software')),
                        DropdownMenuItem(value: 'Accommodation', child: Text('Accommodation')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                        DropdownMenuItem(value: 'KHR', child: Text('KHR (៛)')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                      ],
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amount & Date row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount *',
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return l10n.fieldRequired;
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_expenseDate),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey900),
                            ),
                            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Purpose',
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
                ),
              ),
              const SizedBox(height: 14),

              // Receipt Attachment
              if (!_isEditing) ...[
                if (_receipt != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_receipt!, width: 44, height: 44, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Receipt Attached',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 18),
                          onPressed: _removeReceipt,
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickReceipt,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Attach Receipt (Photo/File)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isEditing ? 'Save Changes' : 'Submit Claim',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}