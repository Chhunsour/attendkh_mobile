import 'package:attendkh/services/network/api_repository.dart';

class AdminSupportTicket {
  final int id;
  final String subject;
  final String? message;
  final String status;
  final String? priority;
  final String? userName;
  final String? companyName;
  final String? createdAt;
  final String? updatedAt;

  const AdminSupportTicket({
    required this.id,
    required this.subject,
    this.message,
    required this.status,
    this.priority,
    this.userName,
    this.companyName,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminSupportTicket.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final company = json['company'] as Map<String, dynamic>?;
    return AdminSupportTicket(
      id: json['id'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String?,
      userName: user?['name'] as String?,
      companyName: company?['name'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'priority': priority ?? 'medium',
  };
}

class AdminSupportTicketsRepository {
  final ApiRepository _api;

  AdminSupportTicketsRepository({ApiRepository? api})
    : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/support-tickets
  Future<List<AdminSupportTicket>> getTickets({
    String? search,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _api.get(
      '/admin/support-tickets',
      queryParameters: queryParams,
    );

    // response.data is unwrapped by ApiResponse.fromJson
    // Paginated: { data: [...], current_page, ... } or direct list
    if (response.data is List) {
      return (response.data as List<dynamic>)
          .map((e) => AdminSupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => AdminSupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// PUT /api/v1/admin/support-tickets/{id}
  Future<AdminSupportTicket> updateTicket(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put('/admin/support-tickets/$id', data: data);
    if (response.data is Map<String, dynamic>) {
      final respData = response.data as Map<String, dynamic>;
      final ticketData =
          respData['data'] as Map<String, dynamic>? ??
          respData['ticket'] as Map<String, dynamic>? ??
          respData;
      return AdminSupportTicket.fromJson(ticketData);
    }
    throw Exception('Invalid response from server');
  }
}
