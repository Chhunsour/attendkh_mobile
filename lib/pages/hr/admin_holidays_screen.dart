import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  State<AdminHolidaysScreen> createState() => _State();
}

class _State extends State<AdminHolidaysScreen> {
  bool _loading = true;
  List<HolidayData> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await AdminOperationsRepository().getHolidays();
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  void _showForm([HolidayData? item]) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: isEdit ? item.name : '');
    final dateCtrl = TextEditingController(text: isEdit ? item.date : '');
    final descCtrl = TextEditingController(text: isEdit ? (item.description ?? '') : '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                    Text(isEdit ? 'Edit Holidays' : 'Add Holidays', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.text),
                    const SizedBox(height: 16),
                    TextField(controller: dateCtrl, decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD) *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.text),
                    const SizedBox(height: 16),
                    TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.text),
                    const SizedBox(height: 16),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.danger)); return; }
                          try {
                            final data = {
                              if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                              if (dateCtrl.text.trim().isNotEmpty) 'date': dateCtrl.text.trim(),
                              if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                              
                            };
                            if (isEdit) {
                              await AdminOperationsRepository().updateHoliday(item.id, data);
                            } else {
                              await AdminOperationsRepository().createHoliday(name: nameCtrl.text.trim(), date: dateCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          } catch (e) {
                            if (!mounted) return;
                            if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                          }
                        },
                        child: Text(isEdit ? 'Save Changes' : 'Create Holidays', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      )
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AdminOperationsRepository().deleteHoliday(id);
                _fetchData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Holidays', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: () => _showForm())
        ],
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading Holidays...')
          : _items.isEmpty
              ? const Center(child: Text('No Holidays found.', style: TextStyle(color: AppColors.grey500)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final e = _items[i];
                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                      child: ListTile(
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900)),
                        subtitle: Text(e.date, style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: AppColors.grey500, size: 20), onPressed: () => _showForm(e)),
                            IconButton(icon: const Icon(Icons.delete, color: AppColors.danger, size: 20), onPressed: () => _confirmDelete(e.id, e.name)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
