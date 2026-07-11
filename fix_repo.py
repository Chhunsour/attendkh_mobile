with open('lib/services/admin_operations_repository.dart', 'r') as f:
    content = f.read()

# Use regex to remove the duplicated classes.
import re
content = re.sub(r'class BranchData \{.*?\}(?=\s*class DepartmentData)', '', content, flags=re.DOTALL)
content = re.sub(r'class DepartmentData \{.*?\}(?=\s*class PositionData)', '', content, flags=re.DOTALL)
content = re.sub(r'class PositionData \{.*?\}(?=\s*class TeamData)', '', content, flags=re.DOTALL)
content = re.sub(r'class TeamData \{.*?\}(?=\s*class AdminOperationsRepository)', '', content, flags=re.DOTALL)

with open('lib/services/admin_operations_repository.dart', 'w') as f:
    f.write(content)
