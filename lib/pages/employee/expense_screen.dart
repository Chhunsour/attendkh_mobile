import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/utils/router/app_router.dart';
import 'package:attendkh/providers/expense_provider.dart';
import 'package:attendkh/services/expense_repository.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/services/network/exceptions.dart';
import 'package:attendkh/utils/image_compressor.dart';
import 'package:attendkh/l10n/app_localizations.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final expenses = expensesAsync.valueOrNull ?? const <ExpenseData>[];
    final bool empty = expenses.isEmpty;

    double sumOf(String status) => expenses
        .where((e) => e.status.toLowerCase() == status)
        .fold<double>(0, (sum, e) => sum + e.amount);
    int countOf(String status) =>
        expenses.where((e) => e.status.toLowerCase() == status).length;

    final filtered = _statusFilter == 'all'
        ? expenses
        : expenses
              .where((e) => e.status.toLowerCase() == _statusFilter)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Claim Expense',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(expensesProvider),
          color: AppColors.primary,
          // The hero runs under the status bar, so the spinner has to drop
          // below it rather than sit on the notch.
          edgeOffset: MediaQuery.paddingOf(context).top + 8,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHero(
                  context,
                  l10n,
                  isDark,
                  pending: sumOf('pending'),
                  approved: sumOf('approved'),
                  paid: sumOf('paid'),
                  claims: expenses.length,
                  loading: expensesAsync.isLoading && empty,
                ),
              ),

              if (expensesAsync.hasError && empty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _errorState(l10n),
                )
              else if (expensesAsync.isLoading && empty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingIndicator(message: l10n.loadingExpenses),
                )
              else ...[
                // Filters bleed to the screen edge so the last chip does not
                // look clipped by the page gutter.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all', expenses.length),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Pending',
                            'pending',
                            countOf('pending'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Approved',
                            'approved',
                            countOf('approved'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip('Paid', 'paid', countOf('paid')),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Rejected',
                            'rejected',
                            countOf('rejected'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: _emptyState(context, l10n, isDark, empty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        final statusColor = _statusColor(e.status);
                        return _ExpenseCard(
                          expense: e,
                          statusColor: statusColor,
                          onTap: () => _showDetailModal(context, e, statusColor),
                          onEdit: e.status == 'pending'
                              ? () => _showEditExpenseSheet(context, ref, e)
                              : null,
                          onDelete: e.status == 'pending'
                              ? () => _deleteExpense(context, ref, e)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient hero: same slab as the dashboard. The headline is the money
  // still owed to you, which is the only figure anyone opens this page for. ──
  Widget _buildHero(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark, {
    required double pending,
    required double approved,
    required double paid,
    required int claims,
    required bool loading,
  }) {
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);

    String money(double v) => '\$${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, AppColors.primary, 0.6)!],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 6,
              16,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _heroIconButton(
                      Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.main);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.expenses,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _heroIconButton(
                      Icons.refresh_rounded,
                      onTap: () => ref.invalidate(expensesProvider),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'AWAITING REIMBURSEMENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            money(pending),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          claims == 1 ? 'across 1 claim' : 'across $claims claims',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _heroStat(
                          'Claims',
                          '$claims',
                          const Color(0xFF93C5FD),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _heroStat(
                          'Approved',
                          money(approved),
                          const Color(0xFF6EE7B7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _heroStat(
                          'Paid',
                          money(paid),
                          const Color(0xFF7DD3FC),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool noClaimsAtAll,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            noClaimsAtAll
                ? l10n.noExpenseClaims
                : 'No ${_capitalizeFilter()} claims',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            noClaimsAtAll
                ? l10n.submitFirstExpense
                : 'Nothing under this status yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
          if (noClaimsAtAll) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _showAddExpenseSheet(context, ref),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: Text(l10n.claimExpense),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _capitalizeFilter() =>
      _statusFilter[0].toUpperCase() + _statusFilter.substring(1);

  Widget _errorState(AppLocalizations l10n) {
    return Center(
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
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.grey200)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.grey300 : AppColors.grey700),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? AppColors.surfaceDarkElevated : AppColors.grey100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? AppColors.grey400 : AppColors.grey600),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExpenseForm(onSubmitted: () => ref.invalidate(expensesProvider)),
    );
  }

  void _showEditExpenseSheet(BuildContext context, WidgetRef ref, ExpenseData e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExpenseForm(
        onSubmitted: () => ref.invalidate(expensesProvider),
        initial: e,
      ),
    );
  }

  void _showDetailModal(BuildContext context, ExpenseData e, Color statusColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              expense.date,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getCategoryL10n(expense.category, l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary(context)),
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
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(context, l10n.title, expense.title),
          _detailRow(context, l10n.category, expense.category),
          _detailRow(context, l10n.amount, '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}'),
          _detailRow(context, l10n.expenseDate, expense.date),
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
            _detailRow(context, l10n.description, expense.description!),
          ],
          if (expense.rejectionReason != null && expense.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.rejectionReason, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey600)),
            const SizedBox(height: 2),
            Text(expense.rejectionReason!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
          if (expense.paidAt != null && expense.paidAt!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(context, l10n.paidAt, expense.paidAt!),
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

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey700 : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Expense Claim' : 'New Expense Claim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.grey400 : AppColors.grey500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: l10n.expenseTitleSubject,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
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
                      dropdownColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Travel', child: Text(l10n.catTravel)),
                        DropdownMenuItem(value: 'Meals', child: Text(l10n.catMeals)),
                        DropdownMenuItem(value: 'Transport', child: Text(l10n.catTransport)),
                        DropdownMenuItem(value: 'Supplies', child: Text(l10n.catSupplies)),
                        DropdownMenuItem(value: 'Software', child: Text(l10n.catSoftware)),
                        DropdownMenuItem(value: 'Accommodation', child: Text(l10n.catAccommodation)),
                        DropdownMenuItem(value: 'Other', child: Text(l10n.catOther)),
                      ],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      dropdownColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                      decoration: InputDecoration(
                        labelText: l10n.currency,
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
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
                        labelText: l10n.amount,
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
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
                          color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_expenseDate),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
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
                  labelText: l10n.descriptionPurpose,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
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
                    label: Text(l10n.attachReceipt),
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
