import re

with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

# Replace: json['employee']?['name'] as String? ?? 
# with: json['employee']?['name'] as String? ?? (json['employee'] != null && json['employee']['first_name'] != null ? '${json['employee']['first_name']} ${json['employee']['last_name'] ?? ''}'.trim() : null) ?? 

new_content = content.replace(
    "json['employee']?['name'] as String? ??",
    "json['employee']?['name'] as String? ?? (json['employee'] != null && json['employee']['first_name'] != null ? '${json['employee']['first_name']} ${json['employee']['last_name'] ?? ''}'.trim() : null) ??"
)

with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(new_content)
