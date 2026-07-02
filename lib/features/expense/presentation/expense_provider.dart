import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/expense/data/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) => ExpenseRepository());
final expensesProvider = FutureProvider.autoDispose<List<ExpenseData>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getExpenses();
});