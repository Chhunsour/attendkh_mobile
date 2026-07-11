with open('lib/pages/hr/company_admin_dashboard_screen.dart', 'r') as f:
    content = f.read()

holiday_button = """              _buildGridItem(
                context,
                title: 'Holidays',
                description: 'Manage company holidays',
                icon: Icons.celebration_rounded,
                color: const Color(0xFFEAB308), // Yellow
                routePath: AppRoutes.adminHolidays,
              ),
"""

if 'title: \'Holidays\'' not in content:
    content = content.replace(
        "              _buildGridItem(\n                context,\n                title: 'Leave Requests',",
        holiday_button + "              _buildGridItem(\n                context,\n                title: 'Leave Requests',"
    )
    with open('lib/pages/hr/company_admin_dashboard_screen.dart', 'w') as f:
        f.write(content)
