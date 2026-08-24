import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';

class ExpenseData {
  final int id;
  final String title;
  final String? description;
  final String category;
  final double amount;
  final String currency;
  final String date;
  final String status;
  final String? employeeName;
  final String? employeeKhmerName;
  final String? employeeId;
  final String? employeeCode;
  final String? employeePhoto;
  final String? employeePosition;
  final String? rejectionReason;
  final String? paidAt;
  final String? receiptPath;

  const ExpenseData({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    required this.status,
    this.employeeName,
    this.employeeKhmerName,
    this.employeeId,
    this.employeeCode,
    this.employeePhoto,
    this.employeePosition,
    this.rejectionReason,
    this.paidAt,
    this.receiptPath,
  });

  /// Safely parse a value that may be a num or a String-encoded number.
  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory ExpenseData.fromJson(Map<String, dynamic> json) {
    String employeeName = '';
    String? employeeKhmerName;
    String? employeeCode;
    String? employeePhoto;
    String? employeePosition;
    final emp = json['employee'];
    if (emp != null && emp is Map) {
      employeeName = emp['full_name'] as String? ?? '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
      if (employeeName.isEmpty) employeeName = emp['name'] as String? ?? '';
      employeeKhmerName = emp['khmer_name'] as String?;
      employeeCode = emp['employee_id'] as String? ?? emp['code'] as String?;
      
      final rawPhoto = emp['photo_url'] as String? ?? emp['photo'] as String? ?? emp['avatar'] as String? ?? emp['profile_photo_url'] as String?;
      if (rawPhoto != null && rawPhoto.isNotEmpty) {
        employeePhoto = rawPhoto.startsWith('http')
            ? rawPhoto
            : '${DioClient.storageUrl}/${rawPhoto.startsWith('/') ? rawPhoto.substring(1) : rawPhoto}';
      }

      final pos = emp['position'];
      if (pos is Map) {
        employeePosition = pos['name'] as String? ?? pos['title'] as String?;
      } else if (pos is String) {
        employeePosition = pos;
      }
    }

    return ExpenseData(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Expense',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'Other',
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'USD',
      date: json['expense_date'] as String? ?? json['date'] as String? ?? json['created_at'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      employeeName: employeeName.isNotEmpty ? employeeName : null,
      employeeKhmerName: employeeKhmerName,
      employeeId: emp is Map ? (emp['id']?.toString() ?? emp['employee_id']?.toString()) : null,
      employeeCode: employeeCode,
      employeePhoto: employeePhoto,
      employeePosition: employeePosition,
      rejectionReason: json['rejection_reason'] as String?,
      paidAt: json['paid_at'] as String?,
      receiptPath: json['receipt_path'] as String?,
    );
  }
}

class ExpenseRepository {
  final ApiRepository _api;
  final Dio _dio;
  ExpenseRepository({ApiRepository? api, Dio? dio})
      : _api = api ?? ApiRepository(),
        _dio = dio ?? DioClient.instance;

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
    required String currency,
    required String expenseDate,
    String? description,
    File? receipt,
  }) async {
    // If a receipt file is provided, use multipart upload (like web)
    if (receipt != null) {
      final formData = FormData.fromMap({
        'title': title,
        'category': category,
        'amount': amount,
        'currency': currency,
        'expense_date': expenseDate,
        if (description != null && description.isNotEmpty) 'description': description,
        'receipt': await MultipartFile.fromFile(
          receipt.path,
          filename: 'receipt.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      final response = await _dio.post('/company/expenses', data: formData);
      final json = response.data as Map<String, dynamic>;
      if (json['data'] != null) {
        return ExpenseData.fromJson(json['data'] as Map<String, dynamic>);
      }
      return ExpenseData.fromJson(json);
    }

    final response = await _api.post(
      '/company/expenses',
      data: {
        'title': title,
        'category': category,
        'amount': amount,
        'currency': currency,
        'expense_date': expenseDate,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    final data = response.data;
    if (data is Map && data['data'] != null) {
      return ExpenseData.fromJson(data['data'] as Map<String, dynamic>);
    }
    return ExpenseData.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateClaim({
    required int id,
    required String title,
    required String category,
    required double amount,
    required String currency,
    required String expenseDate,
    String? description,
  }) async {
    await _api.put(
      '/company/expenses/$id',
      data: {
        'title': title,
        'category': category,
        'amount': amount,
        'currency': currency,
        'expense_date': expenseDate,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
  }

  Future<void> deleteClaim(int id) async {
    await _api.delete('/company/expenses/$id');
  }
}