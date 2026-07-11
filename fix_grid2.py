import re

with open('lib/pages/hr/admin_assets_screen.dart', 'r') as f:
    content = f.read()

pattern_spacer = r"              const SizedBox\(height: 16\),\n              _actionButton\(Icons\.history"
new_spacer = r"              const Spacer(),\n              _actionButton(Icons.history"
content = re.sub(pattern_spacer, new_spacer, content)

with open('lib/pages/hr/admin_assets_screen.dart', 'w') as f:
    f.write(content)
print("done")
