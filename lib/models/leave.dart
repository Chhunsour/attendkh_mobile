import 'package:equatable/equatable.dart';

enum LeaveType { annual, sick, personal, maternity, paternity, unpaid, bereavement }

enum LeaveStatus { pending, approved, rejected, cancelled }

class LeaveRequest extends Equatable {
  final int id;
  final String? leaveType;
  final String startDate;
  final String endDate;
  final int days;
  final String? reason;
  final LeaveStatus status;
  final String? approvedBy;
  final String? approvedAt;
  final String? comment;
  final String createdAt;

  const LeaveRequest({
    required this.id,
    this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, startDate, endDate, status];
}

class LeaveBalance extends Equatable {
  final String type;
  final int allocated;
  final int used;
  final int carriedForward;

  const LeaveBalance({
    required this.type,
    required this.allocated,
    required this.used,
    required this.carriedForward,
  });

  int get remaining => allocated + carriedForward - used;

  double get percentageUsed => allocated > 0 ? used / allocated : 0;

  @override
  List<Object?> get props => [type, allocated, used, carriedForward];
}