import os
import re

files = [
    "lib/features/admin/presentation/admin_announcements_screen.dart",
    "lib/features/admin/presentation/admin_companies_screen.dart",
    "lib/features/admin/presentation/admin_support_tickets_screen.dart",
    "lib/features/admin/presentation/admin_settings_screen.dart",
    "lib/features/admin/presentation/admin_dashboard_screen.dart",
    "lib/features/admin/presentation/admin_audit_logs_screen.dart",
    "lib/features/company_admin/presentation/admin_expenses_screen.dart",
    "lib/features/company_admin/presentation/admin_roles_screen.dart",
    "lib/features/company_admin/presentation/admin_payroll_screen.dart",
    "lib/features/company_admin/presentation/admin_performance_screen.dart",
    "lib/features/company_admin/presentation/admin_resources_screen.dart",
    "lib/features/company_admin/presentation/hr_structure_screen.dart",
    "lib/features/company_admin/presentation/admin_reports_screen.dart",
    "lib/features/company_admin/presentation/admin_attendance_screen.dart",
    "lib/features/company_admin/presentation/admin_recruitment_screen.dart",
    "lib/features/company_admin/presentation/admin_assets_screen.dart",
    "lib/features/company_admin/presentation/admin_leave_screen.dart"
]

for filepath in files:
    if not os.path.exists(filepath): continue
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We want to find the first `return ` inside the build method.
    # The regex looks for `Widget build(...){` and the first `return ` after it.
    # To be safe, we'll find `return ` and replace it, but only if the file doesn't already have Scaffold
    if "return Scaffold(" in content:
        continue
        
    # Find the main return statement of the build method
    # Pattern: match `Widget build(.*?) { ... return `
    
    # A simpler approach: find `    return ` which is usually the top-level return in build
    # because standard formatting indents it by 4 spaces.
    
    if "\n    return " in content:
        content = content.replace("\n    return ", "\n    return Scaffold(backgroundColor: Colors.transparent, body: ")
        
        # We need to add the closing parenthesis `);` at the end of the statement.
        # This is risky if there are multiple `return`s.
        # But wait, these screens usually have only one top-level return for the build method.
        # Actually, adding `);` at the end of the widget tree could be hard if there are other methods.
    
    # Let's use a more robust parsing or just skip it if it's too risky.
    pass

# We will skip python script and do it properly with sed or manual edits for a few files.
