import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class ExpenseData {
  final int id;
  final String title;
  final String? description;
  final double amount;
  final String date;
  final String status;

  const ExpenseData({required this.id, required this.title, this.description, required this.amount, required this.date, required this.status});

  factory ExpenseData.fromJson(Map<String, dynamic> json) {
    return ExpenseData(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['description'] as String? ?? 'Expense',
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: json['date'] as String? ?? json['created_at'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class ExpenseRepository {
  final ApiRepository _api;
  ExpenseRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<ExpenseData>> getExpenses() async {
    final response = await _api.get('/company/expenses');
    final data = response.data;
    if (data is List) return data.map((e) => ExpenseData.fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => ExpenseData.fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }

  Future<ExpenseData> submitClaim({
    required String title,
    required String category,
    required double amount,
    required String expenseDate,
    String? description,
  }) async {
    final response = await _api.post(
      '/company/expenses',
      data: {
        'title': title,
        'category': category,
        'amount': amount,
        'expense_date': expenseDate,
        'description': description,
      },
    );
    final data = response.data;
    if (data is Map && data['data'] != null) {
      return ExpenseData.fromJson(data['data'] as Map<String, dynamic>);
    }
    return ExpenseData.fromJson(data as Map<String, dynamic>);
  }
}