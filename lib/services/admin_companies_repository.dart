import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AdminCompany {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? timezone;
  final String? currency;
  final List<dynamic>? socialMedia;
  final String? status;
  final String? plan;
  final String? planExpiresAt;
  final int? maxEmployees;
  final List<String>? enabledModules;
  final String? logo;
  final String? createdAt;
  final String? businessType;
  final String? companySize;
  final String? vattin;
  final bool? isVatRegistered;
  final bool? telegramEnabled;
  final String? telegramBotToken;
  final String? telegramChatId;
  final String? mapUrl;
  final double? latitude;
  final double? longitude;

  const AdminCompany({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.timezone,
    this.currency,
    this.socialMedia,
    this.status,
    this.plan,
    this.planExpiresAt,
    this.maxEmployees,
    this.enabledModules,
    this.logo,
    this.createdAt,
    this.businessType,
    this.companySize,
    this.vattin,
    this.isVatRegistered,
    this.telegramEnabled,
    this.telegramBotToken,
    this.telegramChatId,
    this.mapUrl,
    this.latitude,
    this.longitude,
  });

  factory AdminCompany.fromJson(Map<String, dynamic> json) {
    List<dynamic> parsedSocialMedia = [];
    final rawSm = json['social_media'];
    if (rawSm is List) {
      parsedSocialMedia = rawSm;
    } else if (rawSm is Map) {
      parsedSocialMedia = rawSm.entries
          .map((e) => {'platform': e.key.toString(), 'url': e.value.toString()})
          .toList();
    }

    List<String>? parsedModules;
    if (json['enabled_modules'] is List) {
      parsedModules = (json['enabled_modules'] as List).map((e) => e.toString()).toList();
    }

    return AdminCompany(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      timezone: json['timezone'] as String?,
      currency: json['currency'] as String?,
      socialMedia: parsedSocialMedia,
      status: json['status'] as String? ?? 'active',
      plan: json['plan'] as String? ?? 'starter',
      planExpiresAt: json['plan_expires_at'] as String?,
      maxEmployees: json['max_employees'] as int?,
      enabledModules: parsedModules,
      logo: json['logo'] as String?,
      createdAt: json['created_at'] as String?,
      businessType: json['business_type'] as String?,
      companySize: json['company_size'] as String?,
      vattin: json['vattin'] as String?,
      isVatRegistered: json['is_vat_registered'] is bool
          ? json['is_vat_registered'] as bool
          : (json['is_vat_registered'] as int?) == 1,
      telegramEnabled: json['telegram_enabled'] is bool
          ? json['telegram_enabled'] as bool
          : (json['telegram_enabled'] as int?) == 1,
      telegramBotToken: json['telegram_bot_token'] as String?,
      telegramChatId: json['telegram_chat_id'] as String?,
      mapUrl: json['map_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'timezone': timezone,
    'currency': currency,
    'social_media': socialMedia,
    'status': status,
    'plan': plan,
    'plan_expires_at': planExpiresAt,
    'max_employees': maxEmployees,
    'enabled_modules': enabledModules,
  };
}

class AdminCompanyCreationResult {
  final AdminCompany company;
  final String? ownerEmail;
  final String? ownerPassword;

  AdminCompanyCreationResult({
    required this.company,
    this.ownerEmail,
    this.ownerPassword,
  });
}

class AdminCompaniesRepository {
  final ApiRepository _api;

  AdminCompaniesRepository({ApiRepository? api})
    : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/companies
  Future<List<AdminCompany>> getCompanies() async {
    final response = await _api.get('/admin/companies');
    List<dynamic> list;
    if (response.data is List) {
      list = response.data as List<dynamic>;
    } else if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      list = data['data'] as List<dynamic>? ?? [];
    } else {
      list = [];
    }
    return list
        .map((e) => AdminCompany.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/admin/companies/{id}
  Future<AdminCompany> getCompany(int id) async {
    final response = await _api.get('/admin/companies/$id');
    final data = _unwrapSingle(response.data);
    return AdminCompany.fromJson(data);
  }

  /// POST /api/v1/admin/companies
  Future<AdminCompanyCreationResult> createCompany(
    Map<String, dynamic> data, {
    String? logoPath,
  }) async {
    final dynamic body;
    if (logoPath != null) {
      body = FormData.fromMap({
        ...data,
        'logo': await MultipartFile.fromFile(logoPath),
      });
    } else {
      body = data;
    }
    final response = await _api.post('/admin/companies', data: body);
    final rawData = _unwrapSingle(response.data);
    final company = AdminCompany.fromJson(rawData);

    String? ownerEmail;
    String? ownerPassword;
    if (rawData['owner_credentials'] is Map) {
      ownerEmail = rawData['owner_credentials']['email']?.toString();
      ownerPassword = rawData['owner_credentials']['password']?.toString();
    }

    return AdminCompanyCreationResult(
      company: company,
      ownerEmail: ownerEmail,
      ownerPassword: ownerPassword,
    );
  }

  /// PUT /api/v1/admin/companies/{id}
  Future<AdminCompany> updateCompany(
    int id,
    Map<String, dynamic> data, {
    String? logoPath,
  }) async {
    final dynamic body;
    final ApiResponse<dynamic> response;
    if (logoPath != null) {
      body = FormData.fromMap({
        ...data,
        '_method': 'PUT',
        'logo': await MultipartFile.fromFile(logoPath),
      });
      response = await _api.post('/admin/companies/$id', data: body);
    } else {
      body = data;
      response = await _api.put('/admin/companies/$id', data: body);
    }
    final company = _unwrapSingle(response.data);
    return AdminCompany.fromJson(company);
  }

  /// Unwrap single-entity response that may be { data: { ... } }
  Map<String, dynamic> _unwrapSingle(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {};
  }

  /// POST /api/v1/admin/companies/{id}/suspend
  Future<void> suspendCompany(int id) async {
    await _api.post('/admin/companies/$id/suspend');
  }

  /// POST /api/v1/admin/companies/{id}/activate
  Future<void> activateCompany(int id) async {
    await _api.post('/admin/companies/$id/activate');
  }

  /// DELETE /api/v1/admin/companies/{id}
  Future<void> deleteCompany(int id) async {
    await _api.delete('/admin/companies/$id');
  }

  /// POST /api/v1/admin/companies/{id}/reset-owner-password
  Future<Map<String, dynamic>> resetOwnerPassword(int id, {String? password}) async {
    final response = await _api.post(
      '/admin/companies/$id/reset-owner-password',
      data: password != null ? {'password': password} : {},
    );
    final data = _unwrapSingle(response.data);
    if (data['owner'] is Map) {
      return Map<String, dynamic>.from(data['owner'] as Map);
    }
    return data;
  }

  /// POST /api/v1/admin/companies/{id}/impersonate
  Future<Map<String, dynamic>> impersonateCompany(int id) async {
    final response = await _api.post('/admin/companies/$id/impersonate');
    final data = _unwrapSingle(response.data);
    return data;
  }

  /// POST /api/v1/admin/companies/{id}/announcement
  Future<void> sendAnnouncement(int id, {required String title, required String message}) async {
    await _api.post(
      '/admin/companies/$id/announcement',
      data: {'title': title, 'message': message},
    );
  }

  /// GET /api/v1/admin/companies/{id}/stats
  Future<Map<String, dynamic>> getCompanyStats(int id) async {
    final response = await _api.get('/admin/companies/$id/stats');
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return (data['data'] as Map<String, dynamic>?) ?? data;
    }
    return {};
  }
}
