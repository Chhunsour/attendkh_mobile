import re

with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

def replacer(match):
    key = match.group(1)
    val = match.group(2)
    return f"if ({val} != null) {key}: {val}"

new_content = re.sub(r"('[^']+')\s*:\s*\?([a-zA-Z0-9_]+)", replacer, content)

with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(new_content)
