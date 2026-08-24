import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
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
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _from = 0;
  int _to = 0;

  final DocumentsRepository _repo = DocumentsRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getDocuments(
        search: _search,
        departmentId: _departmentId,
        page: _currentPage,
      );
      setState(() {
        _documents = res.documents;
        _departments = res.departments;
        _currentPage = res.currentPage;
        _lastPage = res.lastPage;
        _total = res.total;
        _from = res.from;
        _to = res.to;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _changePage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    setState(() => _currentPage = page);
    _fetchData();
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int get _totalStorageBytes {
    return _documents.fold<int>(0, (sum, doc) => sum + (doc.fileSize ?? 0));
  }

  int get _publicDocsCount {
    return _documents.where((d) => d.isPublic).length;
  }

  int get _expiredDocsCount {
    final now = DateTime.now();
    return _documents.where((d) {
      if (d.expiresAt == null || d.expiresAt!.isEmpty) return false;
      final exp = DateTime.tryParse(d.expiresAt!);
      return exp != null && exp.isBefore(now);
    }).length;
  }

  Widget _buildFileIcon(String? mimeType, {double size = 20}) {
    if (mimeType == null) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.grey500.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.insert_drive_file_rounded, color: AppColors.grey600, size: size),
      );
    }
    if (mimeType.contains('pdf')) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: size),
      );
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel') || mimeType.contains('csv')) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.table_chart_rounded, color: AppColors.success, size: size),
      );
    }
    if (mimeType.contains('image')) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_rounded, color: Color(0xFF0284C7), size: 20),
      );
    }
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.description_rounded, color: Colors.indigo, size: size),
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.grey500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.insert_drive_file_rounded, color: AppColors.grey600, size: size),
    );
  }

  void _showPreview(DocumentData doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildFileIcon(doc.mimeType, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (doc.fileName != null)
                          Text(
                            doc.fileName!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey500,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.grey400),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (doc.mimeType != null &&
                        doc.mimeType!.contains('image') &&
                        doc.downloadUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: doc.downloadUrl!,
                          fit: BoxFit.contain,
                          memCacheWidth: 800,
                          placeholder: (_, _) => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                          errorWidget: (_, _, _) => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('Cannot load image preview'),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(36),
                          child: Column(
                            children: [
                              _buildFileIcon(doc.mimeType, size: 28),
                              const SizedBox(height: 14),
                              Text(
                                'File Preview',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Download the file below to view full document contents.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (doc.description != null && doc.description!.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _infoRow('Department', doc.department?.name ?? 'Company-Wide'),
                    _infoRow('Visibility', doc.isPublic ? 'Public' : 'Internal'),
                    if (doc.fileSize != null)
                      _infoRow('Size', _formatBytes(doc.fileSize)),
                    if (doc.expiresAt != null && doc.expiresAt!.isNotEmpty)
                      _infoRow(
                        'Expires',
                        DateFormat('dd MMM yyyy').format(DateTime.parse(doc.expiresAt!)),
                      ),
                    _infoRow('Uploaded by', doc.uploaderName ?? 'Unknown'),
                    if (doc.createdAt != null)
                      _infoRow('Created', doc.createdAt!.substring(0, 10)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _downloadFile(doc);
                        },
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 17),
                        label: const Text(
                          'Download File',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(DocumentData doc) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading file...'),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final rawName = doc.fileName ?? 'document_${doc.id}';
      final safeName = rawName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final savePath = '${dir.path}/$safeName';

      await _repo.downloadDocument(
        doc.id,
        savePath,
        downloadUrl: doc.downloadUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Downloaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open file: ${result.message}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Download failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showForm([DocumentData? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final descCtrl = TextEditingController(
      text: isEdit ? (item.description ?? '') : '',
    );
    final expCtrl = TextEditingController(
      text: isEdit ? (item.expiresAt ?? '') : '',
    );
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
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Document' : 'Upload Document',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.grey400),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.pickFiles();
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
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 34,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedFile?.name ??
                                  (isEdit
                                      ? 'Tap to select replacement file (optional)'
                                      : 'Tap to select file (PDF, Word, Excel, Images)'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId.isEmpty ? null : selectedDeptId,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Company-Wide (All Departments)'),
                        ),
                        ..._departments.map(
                          (d) => DropdownMenuItem(
                            value: d.id.toString(),
                            child: Text(d.name),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setSheetState(() => selectedDeptId = val ?? ''),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () async {
                        final initial = expCtrl.text.isNotEmpty
                            ? DateTime.tryParse(expCtrl.text) ?? DateTime.now()
                            : DateTime.now();
                        final picked = await showCustomDatePicker(
                          context,
                          initialDate: initial,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            expCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expires At',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  expCtrl.text.isNotEmpty
                                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(expCtrl.text))
                                      : 'No expiration (Optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: expCtrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                                    color: expCtrl.text.isNotEmpty ? AppColors.textPrimary(context) : AppColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (expCtrl.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => setSheetState(() => expCtrl.clear()),
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.close_rounded, color: AppColors.grey400, size: 16),
                                    ),
                                  ),
                                const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Checkbox(
                          value: isPublic,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setSheetState(() => isPublic = val ?? false),
                        ),
                        Text(
                          'Public to all employees',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a title')),
                            );
                            return;
                          }
                          if (!isEdit && selectedFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a file')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          setState(() => _loading = true);

                          try {
                            if (isEdit) {
                              await _repo.updateDocument(
                                item.id,
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty ? null : selectedDeptId,
                                isPublic: isPublic,
                                expiresAt: expCtrl.text.isEmpty ? null : expCtrl.text,
                                filePath: selectedFile?.path,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Document updated successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } else {
                              await _repo.uploadDocument(
                                title: titleCtrl.text.trim(),
                                filePath: selectedFile!.path!,
                                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty ? null : selectedDeptId,
                                isPublic: isPublic,
                                expiresAt: expCtrl.text.isEmpty ? null : expCtrl.text,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Document uploaded successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                            _fetchData();
                          } catch (e) {
                            setState(() => _loading = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                        child: Text(
                          isEdit ? 'Update Document' : 'Upload Document',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(int docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                await _repo.deleteDocument(docId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Document deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                _fetchData();
              } catch (e) {
                setState(() => _loading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_total Documents',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Storage: ${_formatBytes(_totalStorageBytes)} • $_publicDocsCount Public files',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildBannerStatPill('Total Files', '$_total'),
              const SizedBox(width: 8),
              _buildBannerStatPill('Storage', _formatBytes(_totalStorageBytes)),
              const SizedBox(width: 8),
              _buildBannerStatPill('Public', '$_publicDocsCount'),
              const SizedBox(width: 8),
              _buildBannerStatPill('Expired', '$_expiredDocsCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentChips() {
    final allItems = [
      {'id': 'all', 'name': 'All'},
      {'id': 'company-wide', 'name': 'Company-Wide'},
      ..._departments.map((d) => {'id': d.id.toString(), 'name': d.name}),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: allItems.map((item) {
          final isSelected = _departmentId == item['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _departmentId = item['id']!);
                _fetchData();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border(context),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item['name']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Documents',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Executive Banner ──
          _buildExecutiveBanner(),

          // ── Search & Filter Controls ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search document title or file...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.grey400),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.grey500),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search = '';
                          _fetchData();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (val) {
                _search = val;
                _fetchData();
              },
            ),
          ),

          // ── Department Filter Pills ──
          _buildDepartmentChips(),
          const SizedBox(height: 6),

          // ── Documents List ──
          Expanded(
            child: _loading
                ? const LoadingIndicator(message: 'Loading Documents...')
                : _documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.grey500.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.folder_open_rounded, size: 30, color: AppColors.grey400),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No documents found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(fontSize: 11, color: AppColors.grey500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _documents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final doc = _documents[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border(context)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFileIcon(doc.mimeType),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textPrimary(context),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (doc.fileName != null)
                                            Text(
                                              doc.fileName!,
                                              style: const TextStyle(
                                                color: AppColors.grey500,
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: doc.isPublic
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.grey500.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: doc.isPublic
                                              ? AppColors.success.withValues(alpha: 0.25)
                                              : AppColors.grey500.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            doc.isPublic ? Icons.public : Icons.lock_outline,
                                            size: 11,
                                            color: doc.isPublic ? AppColors.success : AppColors.grey600,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            doc.isPublic ? 'Public' : 'Internal',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: doc.isPublic ? AppColors.success : AppColors.grey600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Department & Expiration Chips
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                                      ),
                                      child: Text(
                                        doc.department?.name ?? 'Company-Wide',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    if (doc.fileSize != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.grey500.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _formatBytes(doc.fileSize),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey600,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    if (doc.expiresAt != null && doc.expiresAt!.isNotEmpty)
                                      Builder(
                                        builder: (_) {
                                          final expDate = DateTime.tryParse(doc.expiresAt!);
                                          final isExpired = expDate != null && expDate.isBefore(DateTime.now());
                                          final formattedDate = expDate != null
                                              ? DateFormat('dd MMM yyyy').format(expDate)
                                              : doc.expiresAt!;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isExpired
                                                  ? AppColors.danger.withValues(alpha: 0.1)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isExpired
                                                    ? AppColors.danger.withValues(alpha: 0.25)
                                                    : const Color(0xFFFDE68A),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isExpired ? Icons.event_busy_rounded : Icons.event_available_rounded,
                                                  size: 11,
                                                  color: isExpired ? AppColors.danger : const Color(0xFFD97706),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  isExpired ? 'Expired: $formattedDate' : 'Expires: $formattedDate',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isExpired ? AppColors.danger : const Color(0xFFD97706),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Uploader & Date
                                Text(
                                  '${doc.uploaderName ?? 'Unknown'} · ${doc.createdAt?.substring(0, 10) ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey500,
                                  ),
                                ),

                                const Divider(height: 18),

                                // Action Buttons (Compact & Overflow-Proof)
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _showPreview(doc),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.visibility_rounded, size: 13, color: AppColors.primary),
                                            SizedBox(width: 4),
                                            Text(
                                              'View',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _downloadFile(doc),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.download_rounded, size: 13, color: Colors.blue),
                                            SizedBox(width: 4),
                                            Text(
                                              'Download',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Edit',
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => _showForm(doc),
                                      icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.grey600),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => _confirmDelete(doc.id, doc.title),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // ── Pagination Footer ──
          if (_lastPage > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing $_from-$_to of $_total',
                    style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.grey600, size: 18),
                        onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
                      ),
                      Text(
                        '$_currentPage / $_lastPage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.grey600, size: 18),
                        onPressed: _currentPage < _lastPage ? () => _changePage(_currentPage + 1) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
