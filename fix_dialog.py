import re

with open('lib/pages/hr/admin_assets_screen.dart', 'r') as f:
    content = f.read()

load_employees_new = """  Future<void> _loadEmployees(void Function(void Function()) updateState) async {
    updateState(() => _loadingEmployees = true);
    try {
      final repo = AdminOperationsRepository();
      _employees = await repo.getEmployees();
    } catch (_) {
      _employees = [];
    }
    updateState(() => _loadingEmployees = false);
  }"""

content = re.sub(
    r"  Future<void> _loadEmployees\(\) async \{.*?\n  \}",
    load_employees_new,
    content,
    flags=re.DOTALL
)

show_assign_new = """  void _showAssignDialog(AssetData asset) {
    _resetForm();
    _selectedEmployee = null;
    bool fetchStarted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (!fetchStarted && _employees.isEmpty) {
            fetchStarted = true;
            _loadEmployees(setDialogState);
          }

          return AlertDialog("""

content = re.sub(
    r"  void _showAssignDialog\(AssetData asset\) \{\n    _resetForm\(\);\n    _loadEmployees\(\);\n    _selectedEmployee = null;\n\n    showDialog\(\n      context: context,\n      builder: \(ctx\) => StatefulBuilder\(\n        builder: \(ctx, setDialogState\) \{\n          return AlertDialog\(",
    show_assign_new,
    content
)

with open('lib/pages/hr/admin_assets_screen.dart', 'w') as f:
    f.write(content)
