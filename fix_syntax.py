import re

with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

# Replace 'key': ?value with if (value != null) 'key': value
# But wait, it's inside a map literal.
# For example: {'action': 'reject', 'rejection_reason': ?reason}
# should become: {'action': 'reject', if (reason != null) 'rejection_reason': reason}

def replacer(match):
    key = match.group(1)
    val = match.group(2)
    return f"if ({val} != null) {key}: {val}"

# Match 'some_key': ?someValue
new_content = re.sub(r"('[^']+')\s*:\s*\?([a-zA-Z0-9_]+)", replacer, content)

with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(new_content)

