import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart'
    show DepartmentData;
import 'package:mpg_hr_mobile_app/services/hr_repository.dart'
    show PositionData;

class JobPostingData {
  final int id;
  final String title;
  final DepartmentData? department;
  final PositionData? position;
  final String? description;
  final String? requirements;
  final String? responsibilities;
  final String? employmentType;
  final String? location;
  final String? mapUrl;
  final double? salaryMin;
  final double? salaryMax;
  final int positionsAvailable;
  final String? closingDate;
  final String status;
  final String? notes;
  final int candidatesCount;
  final String? createdAt;
  final String? experienceLevel;
  final String? educationLevel;
  final String? skills;
  final String? genderPreference;
  final String? ageRequirement;
  final String? howToApply;
  final String? contactInfo;
  final String? benefits;

  const JobPostingData({
    required this.id,
    required this.title,
    this.department,
    this.position,
    this.description,
    this.requirements,
    this.responsibilities,
    this.employmentType,
    this.location,
    this.mapUrl,
    this.salaryMin,
    this.salaryMax,
    this.positionsAvailable = 1,
    this.closingDate,
    required this.status,
    this.notes,
    this.candidatesCount = 0,
    this.createdAt,
    this.experienceLevel,
    this.educationLevel,
    this.skills,
    this.genderPreference,
    this.ageRequirement,
    this.howToApply,
    this.contactInfo,
    this.benefits,
  });

  factory JobPostingData.fromJson(Map<String, dynamic> json) {
    return JobPostingData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      department: json['department'] != null
          ? DepartmentData.fromJson(json['department'])
          : null,
      position: json['position'] != null
          ? PositionData.fromJson(json['position'])
          : null,
      description: json['description'] as String?,
      requirements: json['requirements'] as String?,
      responsibilities: json['responsibilities'] as String?,
      employmentType: json['employment_type'] as String?,
      location: json['location'] as String?,
      mapUrl: json['map_url'] as String?,
      salaryMin: double.tryParse(json['salary_min']?.toString() ?? ''),
      salaryMax: double.tryParse(json['salary_max']?.toString() ?? ''),
      positionsAvailable:
          int.tryParse(json['positions_available']?.toString() ?? '') ?? 1,
      closingDate: json['closing_date'] as String?,
      status: json['status'] as String? ?? 'open',
      notes: json['notes'] as String?,
      candidatesCount:
          int.tryParse(json['candidates_count']?.toString() ?? '') ?? 0,
      createdAt: json['created_at'] as String?,
      experienceLevel: json['experience_level'] as String?,
      educationLevel: json['education_level'] as String?,
      skills: json['skills'] as String?,
      genderPreference: json['gender_preference'] as String?,
      ageRequirement: json['age_requirement'] as String?,
      howToApply: json['how_to_apply'] as String?,
      contactInfo: json['contact_info'] as String?,
      benefits: json['benefits'] as String?,
    );
  }
}

class CandidateData {
  final int id;
  final String name;
  final String? fullName;
  final String? nameKh;
  final String? email;
  final String? phone;
  final String stage;
  final String? appliedJob;
  final String? coverLetter;
  final int? yearsOfExperience;
  final String? currentPosition;
  final String? currentCompany;
  final double? expectedSalary;
  final String? availableFrom;
  final String? notes;
  final String? resume;

  const CandidateData({
    required this.id,
    required this.name,
    this.fullName,
    this.nameKh,
    this.email,
    this.phone,
    required this.stage,
    this.appliedJob,
    this.coverLetter,
    this.yearsOfExperience,
    this.currentPosition,
    this.currentCompany,
    this.expectedSalary,
    this.availableFrom,
    this.notes,
    this.resume,
  });

  factory CandidateData.fromJson(Map<String, dynamic> json) {
    return CandidateData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      fullName: json['full_name'] as String?,
      nameKh: json['name_kh'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      stage: json['status'] as String? ?? json['stage'] as String? ?? 'applied',
      appliedJob: json['job']?['title'] as String?,
      coverLetter: json['cover_letter'] as String?,
      yearsOfExperience: int.tryParse(
        json['years_of_experience']?.toString() ?? '',
      ),
      currentPosition: json['current_position'] as String?,
      currentCompany: json['current_company'] as String?,
      expectedSalary: double.tryParse(
        json['expected_salary']?.toString() ?? '',
      ),
      availableFrom: json['available_from'] as String?,
      notes: json['notes'] as String?,
      resume: json['resume'] as String?,
    );
  }
}

class RecruitmentJobsResponse {
  final List<JobPostingData> jobs;
  final List<DepartmentData> departments;
  final List<PositionData> positions;

  RecruitmentJobsResponse({
    required this.jobs,
    required this.departments,
    required this.positions,
  });
}

class RecruitmentRepository {
  final ApiRepository _api = ApiRepository();

  Future<RecruitmentJobsResponse> getJobs() async {
    final response = await _api.get('/company/recruitment/jobs');
    final data =
        response.data; // ApiResponse automatically extracts the 'data' envelope

    List<JobPostingData> jobs = [];
    List<DepartmentData> depts = [];
    List<PositionData> pos = [];

    if (data is Map) {
      if (data['jobs'] != null && data['jobs']['data'] != null) {
        jobs = (data['jobs']['data'] as List)
            .map((e) => JobPostingData.fromJson(e))
            .toList();
      }
      if (data['departments'] != null) {
        depts = (data['departments'] as List)
            .map((e) => DepartmentData.fromJson(e))
            .toList();
      }
      if (data['positions'] != null) {
        pos = (data['positions'] as List)
            .map((e) => PositionData.fromJson(e))
            .toList();
      }
    }
    return RecruitmentJobsResponse(
      jobs: jobs,
      departments: depts,
      positions: pos,
    );
  }

  Future<void> createJob(Map<String, dynamic> data) async {
    await _api.post('/company/recruitment/jobs', data: data);
  }

  Future<void> updateJob(int id, Map<String, dynamic> data) async {
    await _api.put('/company/recruitment/jobs/$id', data: data);
  }

  Future<void> deleteJob(int id) async {
    await _api.delete('/company/recruitment/jobs/$id');
  }

  Future<List<CandidateData>> getCandidates(int jobId) async {
    final response = await _api.get(
      '/company/recruitment/jobs/$jobId/candidates',
    );
    final List list = response.data as List? ?? [];
    return list.map((e) => CandidateData.fromJson(e)).toList();
  }

  Future<void> updateCandidateStatus(int candidateId, String status) async {
    await _api.post(
      '/company/recruitment/candidates/$candidateId/status',
      data: {'status': status},
    );
  }

  Future<void> convertToEmployee(int candidateId) async {
    await _api.post('/company/recruitment/candidates/$candidateId/convert');
  }

  Future<void> addCandidate(int jobId, Map<String, dynamic> data) async {
    await _api.post('/company/recruitment/jobs/$jobId/candidates', data: data);
  }

  Future<void> scheduleInterview(
    int candidateId,
    Map<String, dynamic> data,
  ) async {
    await _api.post(
      '/company/recruitment/candidates/$candidateId/interviews',
      data: data,
    );
  }
}
