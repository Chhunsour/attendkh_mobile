class KpiItem {
  final String title;
  final String description;
  final num actual;
  final num target;
  final String unit;
  final num score;
  final String type;

  KpiItem({
    required this.title,
    required this.description,
    required this.actual,
    required this.target,
    required this.unit,
    required this.score,
    required this.type,
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

class KpiData {
  final List<KpiItem> employeeKpis;
  final List<KpiItem> managerKpis;
  final List<KpiItem> ownerKpis;
  final String userRole;
  final KpiMetrics metrics;

  KpiData({
    required this.employeeKpis,
    required this.managerKpis,
    required this.ownerKpis,
    required this.userRole,
    required this.metrics,
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    return KpiData(
      employeeKpis: (json['employeeKpis'] as List?)?.map((e) => KpiItem.fromJson(e)).toList() ?? [],
      managerKpis: (json['managerKpis'] as List?)?.map((e) => KpiItem.fromJson(e)).toList() ?? [],
      ownerKpis: (json['ownerKpis'] as List?)?.map((e) => KpiItem.fromJson(e)).toList() ?? [],
      userRole: json['userRole'] ?? 'employee',
      metrics: KpiMetrics.fromJson(json['metrics'] ?? {}),
    );
  }
}
