import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _State();
}

class _State extends State<AdminDocumentsScreen> {
  bool _loading = true;
  List<DocumentData> _documents = [];
  List<DepartmentData> _departments = [];
  
  String _search = '';
  String _departmentId = 'all';
  
  final DocumentsRepository _repo = DocumentsRepository();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getDocuments(
        search: _search,
        departmentId: _departmentId,
      );
      setState(() {
        _documents = res.documents;
        _departments = res.departments;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  void _showForm([DocumentData? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final descCtrl = TextEditingController(text: isEdit ? (item.description ?? '') : '');
    final expCtrl = TextEditingController(text: isEdit ? (item.expiresAt ?? '') : '');
    String selectedDeptId = isEdit ? (item.departmentId?.toString() ?? '') : '';
    bool isPublic = isEdit ? item.isPublic : false;
    PlatformFile? selectedFile;

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
                    Text(isEdit ? 'Edit Document' : 'Upload Document', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    
                    if (!isEdit) ...[
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles();
                          if (result != null) {
                            setSheetState(() {
                              selectedFile = result.files.first;
                              if (titleCtrl.text.isEmpty) {
                                titleCtrl.text = selectedFile!.name;
                              }
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.none),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file, size: 40, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(selectedFile?.name ?? 'Tap to select file', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId.isEmpty ? null : selectedDeptId,
                      decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Company-Wide')),
                        ..._departments.map((d) => DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                      ],
                      onChanged: (val) => setSheetState(() => selectedDeptId = val ?? ''),
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expCtrl,
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'Expires At', suffixIcon: const Icon(Icons.calendar_today), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) {
                                expCtrl.text = picked.toString().substring(0, 10);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: isPublic,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setSheetState(() => isPublic = val ?? false),
                            ),
                            const Text('Public', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || (!isEdit && selectedFile == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.danger)); 
                            return;
                          }
                          try {
                            if (isEdit) {
                              await _repo.updateDocument(
                                item.id,
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty ? null : selectedDeptId,
                                isPublic: isPublic,
                                expiresAt: expCtrl.text.trim().isEmpty ? null : expCtrl.text.trim(),
                              );
                            } else {
                              await _repo.uploadDocument(
                                filePath: selectedFile!.path!,
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty ? null : selectedDeptId,
                                isPublic: isPublic,
                                expiresAt: expCtrl.text.trim().isEmpty ? null : expCtrl.text.trim(),
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          } catch (e) {
                            if (!mounted) return;
                            if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                          }
                        },
                        child: Text(isEdit ? 'Update Document' : 'Upload Document', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                await _repo.deleteDocument(id);
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

  Widget _buildFileIcon(String? mimeType) {
    if (mimeType == null) return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
    if (mimeType.contains('pdf')) return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return const Icon(Icons.table_chart, color: Colors.green, size: 32);
    if (mimeType.contains('image')) return const Icon(Icons.image, color: Colors.blue, size: 32);
    if (mimeType.contains('word') || mimeType.contains('document')) return const Icon(Icons.description, color: Colors.blueAccent, size: 32);
    return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Documents', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: () => _showForm())
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    _search = val;
                    _fetchData();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _departmentId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Departments')),
                    const DropdownMenuItem(value: 'company-wide', child: Text('Company-Wide')),
                    ..._departments.map((d) => DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _departmentId = val;
                      _fetchData();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingIndicator(message: 'Loading Documents...')
                : _documents.isEmpty
                    ? const Center(child: Text('No documents found.', style: TextStyle(color: AppColors.grey500)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _documents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final doc = _documents[i];
                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFileIcon(doc.mimeType),
                                    Icon(doc.isPublic ? Icons.public : Icons.lock, size: 16, color: doc.isPublic ? Colors.green : Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (doc.fileName != null) Text(doc.fileName!, style: const TextStyle(color: AppColors.grey500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                      child: Text(doc.department?.name ?? 'Company-Wide', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    ),
                                    if (doc.fileSize != null) Text('${(doc.fileSize! / 1024 / 1024).toStringAsFixed(1)} MB', style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${doc.uploaderName ?? 'Unknown'} · ${doc.createdAt?.substring(0, 10) ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showForm(doc),
                                      icon: const Icon(Icons.edit, size: 16, color: AppColors.grey600),
                                      label: const Text('Edit', style: TextStyle(color: AppColors.grey600)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _confirmDelete(doc.id, doc.title),
                                      icon: const Icon(Icons.delete, size: 16, color: AppColors.danger),
                                      label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
