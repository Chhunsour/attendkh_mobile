import re

with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

# Replace: (json['field'] as num?)?.toDouble() 
# with: double.tryParse(json['field']?.toString() ?? '')

new_content = re.sub(
    r"\(json\['([^']+)'\] as num\?\)\?\.toDouble\(\)",
    r"double.tryParse(json['\1']?.toString() ?? '')",
    content
)

with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(new_content)
