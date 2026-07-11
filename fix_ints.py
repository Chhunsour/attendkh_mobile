import re

with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

def replacer_with_fallback(match):
    field = match.group(1)
    fallback = match.group(2)
    return f"int.tryParse(json['{field}']?.toString() ?? '') ?? {fallback}"

def replacer_without_fallback(match):
    field = match.group(1)
    return f"int.tryParse(json['{field}']?.toString() ?? '')"

# Replace: json['field'] as int? ?? fallback
content = re.sub(r"json\['([^']+)'\] as int\? \?\? ([a-zA-Z0-9_\(\)\.]+)", replacer_with_fallback, content)

# Replace remaining: json['field'] as int?
content = re.sub(r"json\['([^']+)'\] as int\?", replacer_without_fallback, content)

with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(content)
