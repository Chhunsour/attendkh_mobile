import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/services/expense_repository.dart';
import 'package:attendkh/providers/branch_switch_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) => ExpenseRepository());
final expensesProvider = FutureProvider.autoDispose<List<ExpenseData>>((ref) async {
  final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;
  return ref.watch(expenseRepositoryProvider).getExpenses(branchId: activeBranchId);
});