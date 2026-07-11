import sys

with open('lib/utils/router/app_router.dart', 'r') as f:
    content = f.read()

# Add route path
if 'static const adminHolidays' not in content:
    content = content.replace(
        "static const hrStructure = '/company-admin/hr-structure';",
        "static const hrStructure = '/company-admin/hr-structure';\n  static const adminHolidays = '/company-admin/holidays';"
    )

# Add GoRoute
if 'AdminHolidaysScreen()' not in content:
    content = content.replace(
        "import 'package:mpg_hr_mobile_app/pages/hr/company_admin_dashboard_screen.dart';",
        "import 'package:mpg_hr_mobile_app/pages/hr/company_admin_dashboard_screen.dart';\nimport 'package:mpg_hr_mobile_app/pages/hr/admin_holidays_screen.dart';"
    )
    
    route = """      GoRoute(
        path: AppRoutes.adminHolidays,
        builder: (context, state) => const AdminHolidaysScreen(),
      ),
"""
    content = content.replace(
        "      GoRoute(\n        path: AppRoutes.hrStructure,",
        route + "      GoRoute(\n        path: AppRoutes.hrStructure,"
    )

with open('lib/utils/router/app_router.dart', 'w') as f:
    f.write(content)

