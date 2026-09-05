import 'package:attendkh/services/network/api_repository.dart';

class UserSupportTicket {
  final int id;
  final int userId;
  final int? companyId;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final String createdAt;

  const UserSupportTicket({
    required this.id,
    required this.userId,
    this.companyId,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory UserSupportTicket.fromJson(Map<String, dynamic> json) {
    return UserSupportTicket(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      companyId: json['company_id'] as int?,
      subject: json['subject'] as String? ?? 'No Subject',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String? ?? 'medium',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class UserSupportTicketsRepository {
  final ApiRepository _api;

  UserSupportTicketsRepository({ApiRepository? api})
      : _api = api ?? ApiRepository();

  /// GET /api/v1/support-tickets
  Future<List<UserSupportTicket>> getTickets() async {
    final response = await _api.get('/support-tickets');
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final list = (map['data'] as List<dynamic>?) ?? [];
      return list
          .map((e) => UserSupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /api/v1/support-tickets
  Future<UserSupportTicket> createTicket({
    required String subject,
    required String message,
    required String priority,
  }) async {
    final response = await _api.post('/support-tickets', data: {
      'subject': subject,
      'message': message,
      'priority': priority,
    });

    if (response.data is Map<String, dynamic>) {
      return UserSupportTicket.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to create ticket');
  }
}
