import re

with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

new_content = content.replace(
"""  factory AssetData.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) => v != null ? (v as num).toDouble() : null;""",
"""  factory AssetData.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }
    
    String? extractName(dynamic emp) {
      if (emp == null) return null;
      if (emp['name'] != null) return emp['name'] as String?;
      if (emp['first_name'] != null) return '${emp['first_name']} ${emp['last_name'] ?? ''}'.trim();
      return null;
    }
"""
)

new_content = new_content.replace(
"""      assignedTo: json['assigned_to']?['name'] as String? ?? json['current_assignment']?['employee']?['name'] as String?,""",
"""      assignedTo: extractName(json['assigned_to']) ?? extractName(json['current_assignment']?['employee']),"""
)


with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(new_content)
