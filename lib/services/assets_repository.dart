import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AssetData {
  final int id;
  final String assetCode;
  final String name;
  final String? category;
  final String? description;
  final String? serialNumber;
  final String? model;
  final String? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final double? calculatedCurrentValue;
  final int? depreciationMonths;
  final String? warrantyExpiryDate;
  final String condition;
  final String status;
  final String? notes;
  final String? assignedTo;
  final String? assignedEmployeeKhmerName;
  final String? assignedEmployeePhoto;
  final String? assignedEmployeePosition;
  final String? assignedDate;
  final int? currentAssignmentId;

  const AssetData({
    required this.id,
    required this.assetCode,
    required this.name,
    this.category,
    this.description,
    this.serialNumber,
    this.model,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.calculatedCurrentValue,
    this.depreciationMonths,
    this.warrantyExpiryDate,
    required this.condition,
    required this.status,
    this.notes,
    this.assignedTo,
    this.assignedEmployeeKhmerName,
    this.assignedEmployeePhoto,
    this.assignedEmployeePosition,
    this.assignedDate,
    this.currentAssignmentId,
  });

  factory AssetData.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final emp = json['current_assignment']?['employee'] ?? json['assigned_to'];
    String? empName;
    String? empKhmerName;
    String? empPhoto;
    String? empPosition;

    if (emp is Map) {
      empName = emp['full_name'] as String? ??
          emp['name'] as String? ??
          ('${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}').trim();
      empKhmerName = emp['khmer_name'] as String?;
      empPhoto = emp['photo_url'] as String? ?? emp['avatar'] as String?;
      if (emp['position'] is Map) {
        empPosition = emp['position']['name'] as String?;
      } else if (emp['position'] is String) {
        empPosition = emp['position'] as String?;
      }
    } else if (emp is String) {
      empName = emp;
    }

    return AssetData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      assetCode: json['asset_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      description: json['description'] as String?,
      serialNumber: json['serial_number'] as String?,
      model: json['model'] as String?,
      purchaseDate: json['purchase_date'] as String?,
      purchasePrice: parseDouble(json['purchase_price']),
      currentValue: parseDouble(json['current_value']),
      calculatedCurrentValue: parseDouble(json['calculated_current_value']),
      depreciationMonths: int.tryParse(json['depreciation_months']?.toString() ?? ''),
      warrantyExpiryDate: json['warranty_expiry_date'] as String?,
      condition: json['condition'] as String? ?? 'good',
      status: json['status'] as String? ?? 'available',
      notes: json['notes'] as String?,
      assignedTo: empName?.isNotEmpty == true ? empName : null,
      assignedEmployeeKhmerName: empKhmerName,
      assignedEmployeePhoto: empPhoto,
      assignedEmployeePosition: empPosition,
      assignedDate: json['assigned_date'] as String? ?? json['current_assignment']?['assigned_date'] as String?,
      currentAssignmentId: int.tryParse(json['current_assignment']?['id']?.toString() ?? ''),
    );
  }

  double get displayValue => calculatedCurrentValue ?? currentValue ?? 0.0;
}

class AssetAssignmentData {
  final int id;
  final String employeeName;
  final String? employeeKhmerName;
  final String? employeePhoto;
  final String? employeePosition;
  final String assignedDate;
  final String? returnedDate;
  final String? conditionAtAssignment;
  final String? conditionAtReturn;
  final String? notes;

  const AssetAssignmentData({
    required this.id,
    required this.employeeName,
    this.employeeKhmerName,
    this.employeePhoto,
    this.employeePosition,
    required this.assignedDate,
    this.returnedDate,
    this.conditionAtAssignment,
    this.conditionAtReturn,
    this.notes,
  });

  factory AssetAssignmentData.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    String empName = '';
    String? empKhmerName;
    String? empPhoto;
    String? empPosition;

    if (emp is Map) {
      empName = emp['full_name'] as String? ??
          emp['name'] as String? ??
          ('${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}').trim();
      empKhmerName = emp['khmer_name'] as String?;
      empPhoto = emp['photo_url'] as String? ?? emp['avatar'] as String?;
      if (emp['position'] is Map) {
        empPosition = emp['position']['name'] as String?;
      } else if (emp['position'] is String) {
        empPosition = emp['position'] as String?;
      }
    } else if (emp is String) {
      empName = emp;
    }

    return AssetAssignmentData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      employeeName: empName.isNotEmpty ? empName : 'Unknown Staff',
      employeeKhmerName: empKhmerName,
      employeePhoto: empPhoto,
      employeePosition: empPosition,
      assignedDate: json['assigned_date'] as String? ?? json['created_at'] as String? ?? '',
      returnedDate: json['returned_date'] as String?,
      conditionAtAssignment: json['condition_at_assignment'] as String?,
      conditionAtReturn: json['condition_at_return'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class AssetsRepository {
  final _api = ApiRepository();

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }

  Future<List<AssetData>> getAssets() async {
    final response = await _api.get('/company/assets');
    return _parseList(response.data, AssetData.fromJson);
  }

  Future<AssetData> createAsset(Map<String, dynamic> data) async {
    final response = await _api.post('/company/assets', data: data);
    return AssetData.fromJson(response.data['data'] ?? response.data);
  }

  Future<AssetData?> updateAsset(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/company/assets/$id', data: data);
    if (response.data is Map &&
        response.data['data'] != null &&
        response.data['data'] is Map<String, dynamic>) {
      return AssetData.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> deleteAsset(int id) async {
    await _api.delete('/company/assets/$id');
  }

  Future<AssetAssignmentData> assignAsset(int assetId, int employeeId, {String? conditionAtAssignment, String? notes}) async {
    final response = await _api.post('/company/assets/$assetId/assign', data: {
      'employee_id': employeeId,
      'condition_at_assignment': conditionAtAssignment,
      'notes': notes,
    });
    return AssetAssignmentData.fromJson(response.data['data'] ?? response.data);
  }

  Future<AssetAssignmentData> returnAsset(int assetId, {String? conditionAtReturn, String? notes}) async {
    final response = await _api.post('/company/assets/$assetId/return', data: {
      'condition_at_return': conditionAtReturn,
      'notes': notes,
    });
    return AssetAssignmentData.fromJson(response.data['data'] ?? response.data);
  }

  Future<List<AssetAssignmentData>> getAssetHistory(int assetId) async {
    final response = await _api.get('/company/assets/$assetId/history');
    return _parseList(response.data, AssetAssignmentData.fromJson);
  }
}
