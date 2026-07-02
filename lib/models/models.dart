/// Re-export all model classes for convenient imports
export 'user.dart';
export 'attendance.dart';
export 'leave.dart';
export 'payslip.dart';

import 'package:equatable/equatable.dart';

class ExpenseClaim extends Equatable {
  final int id;
  final String title;
  final String? description;
  final double amount;
  final String date;
  final String? receiptUrl;
  final String status; // pending, approved, rejected, reimbursed
  final String? approvedBy;
  final String? comment;
  final String createdAt;

  const ExpenseClaim({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.date,
    this.receiptUrl,
    required this.status,
    this.approvedBy,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, amount, status];
}

class Announcement extends Equatable {
  final int id;
  final String title;
  final String content;
  final bool isImportant;
  final bool isPublished;
  final String? publishedAt;
  final String createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, isImportant];
}

class Holiday extends Equatable {
  final int id;
  final String name;
  final String date;
  final String? description;

  const Holiday({
    required this.id,
    required this.name,
    required this.date,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, date];
}