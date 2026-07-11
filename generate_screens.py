import os

screens = [
    {
        'name': 'admin_branches_screen',
        'title': 'Branches',
        'model': 'BranchData',
        'fetch': 'getAllBranches',
        'create': 'createBranch',
        'update': 'updateBranch',
        'delete': 'deleteBranch',
        'fields': [
            {'name': 'Name *', 'key': 'name', 'ctrl': 'nameCtrl', 'req': True, 'type': 'text'},
            {'name': 'Code', 'key': 'code', 'ctrl': 'codeCtrl', 'req': False, 'type': 'text'},
            {'name': 'Address', 'key': 'address', 'ctrl': 'addressCtrl', 'req': False, 'type': 'text'},
            {'name': 'Phone', 'key': 'phone', 'ctrl': 'phoneCtrl', 'req': False, 'type': 'text'},
            {'name': 'Email', 'key': 'email', 'ctrl': 'emailCtrl', 'req': False, 'type': 'text'},
        ],
        'subtitle': "e.code ?? 'No Code'",
    },
    {
        'name': 'admin_departments_screen',
        'title': 'Departments',
        'model': 'DepartmentData',
        'fetch': 'getAllDepartments',
        'create': 'createDepartment',
        'update': 'updateDepartment',
        'delete': 'deleteDepartment',
        'fields': [
            {'name': 'Name *', 'key': 'name', 'ctrl': 'nameCtrl', 'req': True, 'type': 'text'},
            {'name': 'Code', 'key': 'code', 'ctrl': 'codeCtrl', 'req': False, 'type': 'text'},
            {'name': 'Branch ID', 'key': 'branch_id', 'ctrl': 'branchIdCtrl', 'req': False, 'type': 'number'},
        ],
        'subtitle': "e.branchName ?? (e.code ?? 'No Code')",
    },
    {
        'name': 'admin_positions_screen',
        'title': 'Positions',
        'model': 'PositionData',
        'fetch': 'getAllPositions',
        'create': 'createPosition',
        'update': 'updatePosition',
        'delete': 'deletePosition',
        'fields': [
            {'name': 'Name *', 'key': 'name', 'ctrl': 'nameCtrl', 'req': True, 'type': 'text'},
            {'name': 'Code', 'key': 'code', 'ctrl': 'codeCtrl', 'req': False, 'type': 'text'},
            {'name': 'Department ID', 'key': 'department_id', 'ctrl': 'deptIdCtrl', 'req': False, 'type': 'number'},
            {'name': 'Level', 'key': 'level', 'ctrl': 'levelCtrl', 'req': False, 'type': 'text'},
        ],
        'subtitle': "e.departmentName ?? (e.level ?? 'No Level')",
    },
    {
        'name': 'admin_teams_screen',
        'title': 'Teams',
        'model': 'TeamData',
        'fetch': 'getAllTeams',
        'create': 'createTeam',
        'update': 'updateTeam',
        'delete': 'deleteTeam',
        'fields': [
            {'name': 'Name *', 'key': 'name', 'ctrl': 'nameCtrl', 'req': True, 'type': 'text'},
            {'name': 'Description', 'key': 'description', 'ctrl': 'descCtrl', 'req': False, 'type': 'text'},
            {'name': 'Department ID', 'key': 'department_id', 'ctrl': 'deptIdCtrl', 'req': False, 'type': 'number'},
        ],
        'subtitle': "e.departmentName ?? 'No Department'",
    },
    {
        'name': 'admin_holidays_screen',
        'title': 'Holidays',
        'model': 'HolidayData',
        'fetch': 'getAllHolidays',
        'create': 'createHoliday',
        'update': 'updateHoliday',
        'delete': 'deleteHoliday',
        'fields': [
            {'name': 'Name *', 'key': 'name', 'ctrl': 'nameCtrl', 'req': True, 'type': 'text'},
            {'name': 'Date (YYYY-MM-DD) *', 'key': 'date', 'ctrl': 'dateCtrl', 'req': True, 'type': 'text'},
            {'name': 'Description', 'key': 'description', 'ctrl': 'descCtrl', 'req': False, 'type': 'text'},
        ],
        'subtitle': "e.date",
    }
]

template = """import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class {className} extends StatefulWidget {{
  const {className}({{super.key}});

  @override
  State<{className}> createState() => _State();
}}

class _State extends State<{className}> {{
  bool _loading = true;
  List<{model}> _items = [];

  @override
  void initState() {{
    super.initState();
    _fetchData();
  }}

  Future<void> _fetchData() async {{
    setState(() => _loading = true);
    try {{
      final res = await AdminOperationsRepository().{fetch}();
      setState(() {{
        _items = res;
        _loading = false;
      }});
    }} catch (e) {{
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }}
  }}

  void _showForm([{model}? item]) {{
    final isEdit = item != null;
    {controllers}
    bool isActive = true;
    if (isEdit) {{
      try {{ isActive = (item as dynamic).isActive; }} catch(_) {{}}
    }}
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {{
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? 'Edit {title}' : 'Add {title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    {fieldsUI}
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {{
                          {validation}
                          try {{
                            final data = {{
                              {dataMap}
                            }};
                            if (isEdit) {{
                              await AdminOperationsRepository().{update}(item.id, data);
                            }} else {{
                              {createCall}
                            }}
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          }} catch (e) {{
                            if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                          }}
                        }},
                        child: Text(isEdit ? 'Save Changes' : 'Create {title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }}
      )
    );
  }}

  void _confirmDelete(int id, String name) {{
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {{
              Navigator.pop(ctx);
              try {{
                await AdminOperationsRepository().{delete}(id);
                _fetchData();
              }} catch (e) {{
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
              }}
            }},
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      )
    );
  }}

  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('{title}', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: () => _showForm())
        ],
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading {title}...')
          : _items.isEmpty
              ? const Center(child: Text('No {title} found.', style: TextStyle(color: AppColors.grey500)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {{
                    final e = _items[i];
                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                      child: ListTile(
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900)),
                        subtitle: Text({subtitle}, style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: AppColors.grey500, size: 20), onPressed: () => _showForm(e)),
                            IconButton(icon: const Icon(Icons.delete, color: AppColors.danger, size: 20), onPressed: () => _confirmDelete(e.id, e.name)),
                          ],
                        ),
                      ),
                    );
                  }},
                ),
    );
  }}
}}
"""

for screen in screens:
    class_name = ''.join(word.title() for word in screen['name'].split('_'))
    
    controllers = ""
    for f in screen['fields']:
        init_val = f"item.{f['key']}" if f['type'] == 'text' else f"item.{f['key']}?.toString()"
        if screen['name'] == 'admin_holidays_screen' and f['key'] == 'date':
            init_val = "item.date"
        
        # special check for active
        controllers += f"final {f['ctrl']} = TextEditingController(text: isEdit ? ({init_val} ?? '') : '');\n    "

    fieldsUI = ""
    for f in screen['fields']:
        keyboard = "TextInputType.number" if f['type'] == 'number' else "TextInputType.text"
        fieldsUI += f"""TextField(controller: {f['ctrl']}, decoration: InputDecoration(labelText: '{f['name']}', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: {keyboard}),\n                    const SizedBox(height: 16),\n                    """

    validation = "if ("
    reqs = [f"{f['ctrl']}.text.trim().isEmpty" for f in screen['fields'] if f['req']]
    if reqs:
        validation += " || ".join(reqs) + ") { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.danger)); return; }"
    else:
        validation = ""

    dataMap = ""
    for f in screen['fields']:
        if f['type'] == 'number':
            dataMap += f"if ({f['ctrl']}.text.trim().isNotEmpty) '{f['key']}': int.tryParse({f['ctrl']}.text.trim()),\n                              "
        else:
            dataMap += f"if ({f['ctrl']}.text.trim().isNotEmpty) '{f['key']}': {f['ctrl']}.text.trim(),\n                              "
    
    if screen['model'] == 'HolidayData':
        createCall = f"await AdminOperationsRepository().createHoliday(name: {screen['fields'][0]['ctrl']}.text.trim(), date: {screen['fields'][1]['ctrl']}.text.trim(), description: {screen['fields'][2]['ctrl']}.text.trim().isEmpty ? null : {screen['fields'][2]['ctrl']}.text.trim());"
    else:
        createCall = f"await AdminOperationsRepository().create{screen['title'][:-1]}(data);"

    file_content = template.format(
        className=class_name,
        title=screen['title'],
        model=screen['model'],
        fetch=screen['fetch'],
        update=screen['update'],
        delete=screen['delete'],
        controllers=controllers,
        fieldsUI=fieldsUI,
        validation=validation,
        dataMap=dataMap,
        createCall=createCall,
        subtitle=screen['subtitle']
    )

    with open(f"lib/pages/hr/{screen['name']}.dart", "w") as file:
        file.write(file_content)

