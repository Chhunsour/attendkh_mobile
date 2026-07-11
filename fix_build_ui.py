import re

with open('lib/pages/hr/admin_reports_screen.dart', 'r') as f:
    content = f.read()

old_build_end = r"            if \(_isLoading\) \.\.\.\[[\s\S]*?            \],\n          \],\n        \),\n      \),\n    \);"

new_build_end = """            if (_isLoading) ...[
              const SizedBox(height: 16),
              const LoadingIndicator(message: 'Generating report...'),
            ],
          ],
        ),
      ),
    );"""

content = re.sub(old_build_end, new_build_end, content, flags=re.MULTILINE)

with open('lib/pages/hr/admin_reports_screen.dart', 'w') as f:
    f.write(content)

