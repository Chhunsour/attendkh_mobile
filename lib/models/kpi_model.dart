class KpiItem {
  final String title;
  final String description;
  final num actual;
  final num target;
  final String unit;
  final num score;
  final String type;
  final Map<String, dynamic> extra;

  KpiItem({
    required this.title,
    required this.description,
    required this.actual,
    required this.target,
    required this.unit,
    required this.score,
    required this.type,
    this.extra = const {},
  });

  factory KpiItem.fromJson(Map<String, dynamic> json) {
    return KpiItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      actual: json['actual'] ?? 0,
      target: json['target'] ?? 0,
      unit: json['unit'] ?? '',
      score: json['score'] ?? 0,
      type: json['type'] ?? '',
      extra: (json['extra'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class KpiMetrics {
  final num overallScore;
  final String cycleStatus;
  final num branchAverage;
  final num companyAverage;

  KpiMetrics({
    required this.overallScore,
    required this.cycleStatus,
    required this.branchAverage,
    required this.companyAverage,
  });

  factory KpiMetrics.fromJson(Map<String, dynamic> json) {
    return KpiMetrics(
      overallScore: json['overallScore'] ?? 0,
      cycleStatus: json['cycleStatus'] ?? '',
      branchAverage: json['branchAverage'] ?? 0,
      companyAverage: json['companyAverage'] ?? 0,
    );
  }
}

class KpiDistribution {
  final int onTrack;
  final int moderate;
  final int atRisk;

  KpiDistribution({
    required this.onTrack,
    required this.moderate,
    required this.atRisk,
  });

  factory KpiDistribution.fromJson(Map<String, dynamic> json) {
    return KpiDistribution(
      onTrack: json['onTrack'] ?? 0,
      moderate: json['moderate'] ?? 0,
      atRisk: json['atRisk'] ?? 0,
    );
  }
}

class DepartmentAttainmentItem {
  final String name;
  final num score;
  final int goalsCount;

  DepartmentAttainmentItem({
    required this.name,
    required this.score,
    required this.goalsCount,
  });

  factory DepartmentAttainmentItem.fromJson(Map<String, dynamic> json) {
    return DepartmentAttainmentItem(
      name: json['name'] ?? '',
      score: json['score'] ?? 0,
      goalsCount: json['goals_count'] ?? 0,
    );
  }
}

class TopPerformerItem {
  final int id;
  final String name;
  final String? photo;
  final String department;
  final String position;
  final num score;
  final int goalsCount;

  TopPerformerItem({
    required this.id,
    required this.name,
    this.photo,
    required this.department,
    required this.position,
    required this.score,
    required this.goalsCount,
  });

  factory TopPerformerItem.fromJson(Map<String, dynamic> json) {
    return TopPerformerItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      photo: json['photo'],
      department: json['department'] ?? '',
      position: json['position'] ?? '',
      score: json['score'] ?? 0,
      goalsCount: json['goals_count'] ?? 0,
    );
  }
}

class KpiAttainmentSummary {
  final num overallAttainment;
  final int totalGoals;
  final int completedGoals;
  final int inProgressGoals;
  final KpiDistribution distribution;
  final List<DepartmentAttainmentItem> departmentAttainment;
  final List<TopPerformerItem> topPerformers;

  KpiAttainmentSummary({
    required this.overallAttainment,
    required this.totalGoals,
    required this.completedGoals,
    required this.inProgressGoals,
    required this.distribution,
    required this.departmentAttainment,
    required this.topPerformers,
  });

  factory KpiAttainmentSummary.fromJson(Map<String, dynamic> json) {
    return KpiAttainmentSummary(
      overallAttainment: json['overallAttainment'] ?? 0,
      totalGoals: json['totalGoals'] ?? 0,
      completedGoals: json['completedGoals'] ?? 0,
      inProgressGoals: json['inProgressGoals'] ?? 0,
      distribution: KpiDistribution.fromJson(json['distribution'] ?? {}),
      departmentAttainment: (json['departmentAttainment'] as List?)
              ?.map((e) => DepartmentAttainmentItem.fromJson(e))
              .toList() ??
          [],
      topPerformers: (json['topPerformers'] as List?)
              ?.map((e) => TopPerformerItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class KpiTemplateItem {
  final int id;
  final String title;
  final String? description;
  final String? targetValue;
  final String unit;
  final String type;
  final int? departmentId;
  final String? departmentName;
  final bool isActive;

  KpiTemplateItem({
    required this.id,
    required this.title,
    this.description,
    this.targetValue,
    required this.unit,
    required this.type,
    this.departmentId,
    this.departmentName,
    this.isActive = true,
  });

  factory KpiTemplateItem.fromJson(Map<String, dynamic> json) {
    return KpiTemplateItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      targetValue: json['target_value']?.toString(),
      unit: json['unit'] ?? '%',
      type: json['type'] ?? 'individual',
      departmentId: json['department_id'],
      departmentName: json['department']?['name'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class EmployeeShortInfo {
  final int id;
  final String fullName;
  final String? employeeId;
  final String? departmentName;
  final String? positionName;
  final String? photoUrl;

  EmployeeShortInfo({
    required this.id,
    required this.fullName,
    this.employeeId,
    this.departmentName,
    this.positionName,
    this.photoUrl,
  });

  factory EmployeeShortInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeShortInfo(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? json['name'] ?? '',
      employeeId: json['employee_id'],
      departmentName: json['department']?['name'],
      positionName: json['position']?['name'],
      photoUrl: json['photo_url'] ?? json['photo'],
    );
  }
}

class EmployeeKpiItem {
  final int id;
  final int employeeId;
  final String title;
  final String? description;
  final String unit;
  final num targetValue;
  final num actualValue;
  final num weightPercentage;
  final String? employeeNotes;
  final String? managerNotes;
  final String status;
  final EmployeeShortInfo? employee;
  final KpiTemplateItem? template;

  EmployeeKpiItem({
    required this.id,
    required this.employeeId,
    required this.title,
    this.description,
    required this.unit,
    required this.targetValue,
    required this.actualValue,
    required this.weightPercentage,
    this.employeeNotes,
    this.managerNotes,
    required this.status,
    this.employee,
    this.template,
  });

  num get progressPercent {
    if (targetValue <= 0) return 100;
    return ((actualValue / targetValue) * 100).clamp(0, 150);
  }

  factory EmployeeKpiItem.fromJson(Map<String, dynamic> json) {
    return EmployeeKpiItem(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      unit: json['unit'] ?? '%',
      targetValue: num.tryParse(json['target_value']?.toString() ?? '0') ?? 0,
      actualValue: num.tryParse(json['actual_value']?.toString() ?? '0') ?? 0,
      weightPercentage:
          num.tryParse(json['weight_percentage']?.toString() ?? '10') ?? 10,
      employeeNotes: json['employee_notes'],
      managerNotes: json['manager_notes'],
      status: json['status'] ?? 'pending',
      employee: json['employee'] != null
          ? EmployeeShortInfo.fromJson(json['employee'])
          : null,
      template: json['template'] != null
          ? KpiTemplateItem.fromJson(json['template'])
          : null,
    );
  }
}

class KpiData {
  final List<KpiItem> employeeKpis;
  final List<KpiItem> managerKpis;
  final List<KpiItem> ownerKpis;
  final String userRole;
  final KpiMetrics metrics;
  final KpiAttainmentSummary? attainmentSummary;
  final List<KpiTemplateItem> templates;
  final List<EmployeeKpiItem> assignments;

  KpiData({
    required this.employeeKpis,
    required this.managerKpis,
    required this.ownerKpis,
    required this.userRole,
    required this.metrics,
    this.attainmentSummary,
    this.templates = const [],
    this.assignments = const [],
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    return KpiData(
      employeeKpis: (json['employeeKpis'] as List?)
              ?.map((e) => KpiItem.fromJson(e))
              .toList() ??
          [],
      managerKpis: (json['managerKpis'] as List?)
              ?.map((e) => KpiItem.fromJson(e))
              .toList() ??
          [],
      ownerKpis: (json['ownerKpis'] as List?)
              ?.map((e) => KpiItem.fromJson(e))
              .toList() ??
          [],
      userRole: json['userRole'] ?? 'employee',
      metrics: KpiMetrics.fromJson(json['metrics'] ?? {}),
      attainmentSummary: json['attainmentSummary'] != null
          ? KpiAttainmentSummary.fromJson(json['attainmentSummary'])
          : null,
      templates: (json['templates'] as List?)
              ?.map((e) => KpiTemplateItem.fromJson(e))
              .toList() ??
          [],
      assignments: (json['assignments'] as List?)
              ?.map((e) => EmployeeKpiItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
