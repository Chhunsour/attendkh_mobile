import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart'
    show DepartmentData;
import 'package:mpg_hr_mobile_app/services/directory_repository.dart'
    show EmployeeData;

class PerformanceReviewData {
  final int id;
  final EmployeeData? employee;
  final EmployeeData? reviewer;
  final String? reviewPeriod;
  final String reviewType;
  final String status;
  final String? reviewDate;
  final String? periodStart;
  final String? periodEnd;
  final int? overallRating;
  final String? strengths;
  final String? areasForImprovement;
  final String? goals;
  final String? comments;

  const PerformanceReviewData({
    required this.id,
    this.employee,
    this.reviewer,
    this.reviewPeriod,
    required this.reviewType,
    required this.status,
    this.reviewDate,
    this.periodStart,
    this.periodEnd,
    this.overallRating,
    this.strengths,
    this.areasForImprovement,
    this.goals,
    this.comments,
  });

  factory PerformanceReviewData.fromJson(Map<String, dynamic> json) {
    return PerformanceReviewData(
      id: json['id'] as int,
      employee: json['employee'] != null
          ? EmployeeData.fromJson(json['employee'])
          : null,
      reviewer: json['reviewer'] != null
          ? EmployeeData.fromJson(json['reviewer'])
          : null,
      reviewPeriod: json['review_period'] as String?,
      reviewType: json['review_type'] as String? ?? 'manager',
      status: json['status'] as String? ?? 'draft',
      reviewDate: json['review_date'] as String?,
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      overallRating: json['overall_rating'] != null
          ? int.tryParse(json['overall_rating'].toString())
          : null,
      strengths: json['strengths'] as String?,
      areasForImprovement: json['areas_for_improvement'] as String?,
      goals: json['goals'] as String?,
      comments: json['comments'] as String?,
    );
  }
}

class TrainingCourseData {
  final int id;
  final String title;
  final String? description;
  final String? content;
  final DepartmentData? department;
  final int? departmentId;
  final String? coverImage;
  final String? level;
  final int? durationHours;
  final String? instructor;
  final String? location;
  final int? maxParticipants;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? notes;
  final int? enrollmentsCount;

  const TrainingCourseData({
    required this.id,
    required this.title,
    this.description,
    this.content,
    this.department,
    this.departmentId,
    this.coverImage,
    this.level,
    this.durationHours,
    this.instructor,
    this.location,
    this.maxParticipants,
    required this.status,
    this.startDate,
    this.endDate,
    this.notes,
    this.enrollmentsCount,
  });

  static String? _resolveImageUrl(dynamic jsonVal) {
    if (jsonVal == null) return null;
    String raw = jsonVal.toString().trim();
    if (raw.isEmpty) return null;

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    String cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
    if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.substring(8);
    }

    return 'https://pub-ccd9b4a59b6e4eddb12ef2a2c45e75c7.r2.dev/$cleanPath';
  }

  factory TrainingCourseData.fromJson(Map<String, dynamic> json) {
    final rawCover = _resolveImageUrl(
      json['cover_image_url'] ?? json['cover_image'],
    );

    return TrainingCourseData(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      content: json['content'] as String?,
      department: json['department'] != null
          ? DepartmentData.fromJson(json['department'])
          : null,
      departmentId: json['department_id'] as int?,
      coverImage: rawCover,
      level: json['level'] as String?,
      durationHours: json['duration_hours'] != null
          ? int.tryParse(json['duration_hours'].toString())
          : null,
      instructor: json['instructor'] as String?,
      location: json['location'] as String?,
      maxParticipants: json['max_participants'] != null
          ? int.tryParse(json['max_participants'].toString())
          : null,
      status: json['status'] as String? ?? 'draft',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      notes: json['notes'] as String?,
      enrollmentsCount: json['enrollments_count'] != null
          ? int.tryParse(json['enrollments_count'].toString())
          : null,
    );
  }
}

class PerformanceReviewsResponse {
  final List<PerformanceReviewData> reviews;
  final List<String> periods;
  final List<EmployeeData> employees;
  final int currentPage;
  final int lastPage;
  final int total;
  final int from;
  final int to;

  PerformanceReviewsResponse({
    required this.reviews,
    required this.periods,
    required this.employees,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.from = 0,
    this.to = 0,
  });
}

class TrainingsResponse {
  final List<TrainingCourseData> trainings;
  final List<DepartmentData> departments;
  final int currentPage;
  final int lastPage;
  final int total;
  final int from;
  final int to;

  TrainingsResponse({
    required this.trainings,
    required this.departments,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.from = 0,
    this.to = 0,
  });
}

class PerformanceRepository {
  final ApiRepository _api;
  PerformanceRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  // Reviews
  Future<PerformanceReviewsResponse> getReviews({
    String? search,
    String? period,
    String? type,
    int? branchId,
    int page = 1,
  }) async {
    final Map<String, dynamic> query = {'page': page};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (period != null && period != 'all') query['review_period'] = period;
    if (type != null && type != 'all') query['review_type'] = type;
    if (branchId != null) query['branch_id'] = branchId;

    final response = await _api.get(
      '/company/performance/reviews',
      queryParameters: query,
    );
    final data = response.data;

    List<PerformanceReviewData> revs = [];
    List<String> pers = [];
    List<EmployeeData> emps = [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;
    int from = 0;
    int to = 0;

    if (data is Map && data['reviews'] != null) {
      final reviewsMap = data['reviews'] as Map;
      if (reviewsMap['data'] != null) {
        revs = (reviewsMap['data'] as List)
            .map((e) => PerformanceReviewData.fromJson(e))
            .toList();
      }
      if (data['periods'] != null) {
        pers = (data['periods'] as List).map((e) => e.toString()).toList();
      }
      if (data['employees'] != null) {
        emps = (data['employees'] as List)
            .map((e) => EmployeeData.fromJson(e))
            .toList();
      }
      currentPage = (reviewsMap['current_page'] as num?)?.toInt() ?? 1;
      lastPage = (reviewsMap['last_page'] as num?)?.toInt() ?? 1;
      total = (reviewsMap['total'] as num?)?.toInt() ?? 0;
      from = (reviewsMap['from'] as num?)?.toInt() ?? 0;
      to = (reviewsMap['to'] as num?)?.toInt() ?? 0;
    }
    return PerformanceReviewsResponse(
      reviews: revs,
      periods: pers,
      employees: emps,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      from: from,
      to: to,
    );
  }

  Future<PerformanceReviewData> createReview(Map<String, dynamic> data) async {
    final response = await _api.post(
      '/company/performance/reviews',
      data: data,
    );
    return PerformanceReviewData.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> updateReview(int id, Map<String, dynamic> data) async {
    await _api.put('/company/performance/reviews/$id', data: data);
  }

  Future<void> submitReview(int id) async =>
      _api.post('/company/performance/reviews/$id/submit');
  Future<void> acknowledgeReview(int id) async =>
      _api.post('/company/performance/reviews/$id/acknowledge');
  Future<void> deleteReview(int id) async =>
      _api.delete('/company/performance/reviews/$id');

  // Trainings
  Future<TrainingsResponse> getTrainings({
    String? search,
    String? departmentId,
    int page = 1,
  }) async {
    final Map<String, dynamic> query = {'page': page};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (departmentId != null && departmentId != 'all') {
      query['department_id'] = departmentId;
    }

    final response = await _api.get(
      '/company/performance/trainings',
      queryParameters: query,
    );
    final data = response.data;

    List<TrainingCourseData> trs = [];
    List<DepartmentData> depts = [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;
    int from = 0;
    int to = 0;

    if (data is Map && data['trainings'] != null) {
      final trainingsMap = data['trainings'] as Map;
      if (trainingsMap['data'] != null) {
        trs = (trainingsMap['data'] as List)
            .map((e) => TrainingCourseData.fromJson(e))
            .toList();
      }
      if (data['departments'] != null) {
        depts = (data['departments'] as List)
            .map((e) => DepartmentData.fromJson(e))
            .toList();
      }
      currentPage = (trainingsMap['current_page'] as num?)?.toInt() ?? 1;
      lastPage = (trainingsMap['last_page'] as num?)?.toInt() ?? 1;
      total = (trainingsMap['total'] as num?)?.toInt() ?? 0;
      from = (trainingsMap['from'] as num?)?.toInt() ?? 0;
      to = (trainingsMap['to'] as num?)?.toInt() ?? 0;
    }
    return TrainingsResponse(
      trainings: trs,
      departments: depts,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      from: from,
      to: to,
    );
  }

  Future<TrainingCourseData> createTraining(
    Map<String, dynamic> data, {
    String? coverImagePath,
  }) async {
    FormData formData = FormData.fromMap(data);
    if (coverImagePath != null) {
      final fileName = coverImagePath.split('/').last;
      formData.files.add(
        MapEntry(
          'cover_image',
          await MultipartFile.fromFile(
            coverImagePath,
            filename: fileName.contains('.') ? fileName : 'cover_image.webp',
          ),
        ),
      );
    }
    final response = await _api.post(
      '/company/performance/trainings',
      data: formData,
    );
    return TrainingCourseData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateTraining(
    int id,
    Map<String, dynamic> data, {
    String? coverImagePath,
  }) async {
    // Laravel PHP needs POST + _method=PUT to parse FormData correctly with files.
    data['_method'] = 'PUT';
    FormData formData = FormData.fromMap(data);
    if (coverImagePath != null) {
      final fileName = coverImagePath.split('/').last;
      formData.files.add(
        MapEntry(
          'cover_image',
          await MultipartFile.fromFile(
            coverImagePath,
            filename: fileName.contains('.') ? fileName : 'cover_image.webp',
          ),
        ),
      );
    }
    await _api.post('/company/performance/trainings/$id', data: formData);
  }

  Future<void> deleteTraining(int id) async =>
      _api.delete('/company/performance/trainings/$id');
  Future<void> enrollEmployee(int trainingId, int employeeId) async =>
      _api.post(
        '/company/performance/trainings/$trainingId/enroll',
        data: {'employee_id': employeeId},
      );

  Future<List<Map<String, dynamic>>> getTrainingEnrollments(
    int trainingId,
  ) async {
    final response = await _api.get(
      '/company/performance/trainings/$trainingId/enrollments',
    );
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    if (data is Map && data['data'] != null) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  // Employee Self-Service Trainings
  Future<List<TrainingCourseData>> getAvailableTrainings() async {
    final response = await _api.get('/company/available-trainings');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => TrainingCourseData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List)
          .map((e) => TrainingCourseData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMyTrainings() async {
    final response = await _api.get('/company/my-trainings');
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    if (data is Map && data['data'] != null) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  Future<void> selfEnroll(int trainingId) async {
    await _api.post('/company/trainings/$trainingId/self-enroll');
  }
}
