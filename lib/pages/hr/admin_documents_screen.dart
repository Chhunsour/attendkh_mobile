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

  void _showPreview(DocumentData doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildFileIcon(doc.mimeType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.title,
                                style: TextStyle(
                                  fontSize: 16,
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
                                    fontSize: 12,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
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
                        borderRadius: BorderRadius.circular(12),
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
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              _buildFileIcon(doc.mimeType),
                              const SizedBox(height: 16),
                              const Text(
                                'Preview not available',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Download the file to view it.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (doc.description != null &&
                        doc.description!.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _infoRow(
                      'Department',
                      doc.department?.name ?? 'Company-Wide',
                    ),
                    _infoRow('Visibility', doc.isPublic ? 'Public' : 'Private'),
                    if (doc.fileSize != null)
                      _infoRow(
                        'Size',
                        '${(doc.fileSize! / 1024 / 1024).toStringAsFixed(1)} MB',
                      ),
                    if (doc.expiresAt != null && doc.expiresAt!.isNotEmpty)
                      _infoRow(
                        'Expires',
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(doc.expiresAt!)),
                      ),
                    _infoRow('Uploaded by', doc.uploaderName ?? 'Unknown'),
                    if (doc.createdAt != null)
                      _infoRow('Created', doc.createdAt!.substring(0, 10)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _downloadFile(doc);
                        },
                        icon: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Download',
                          style: TextStyle(
                            color: Colors.white,
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
      padding: const EdgeInsets.only(bottom: 12),
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
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
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
            content: Text('Downloading...'),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Document' : 'Upload Document',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                            style: BorderStyle.none,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.upload_file,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedFile?.name ??
                                  (isEdit
                                      ? 'Tap to select replacement file (optional)'
                                      : 'Tap to select file'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId.isEmpty
                          ? null
                          : selectedDeptId,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Company-Wide'),
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
                    const SizedBox(height: 16),

                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        final initial = expCtrl.text.isNotEmpty
                            ? (DateTime.tryParse(expCtrl.text) ??
                                  DateTime.now())
                            : DateTime.now();
                        final picked = await showCustomDatePicker(
                          context,
                          initialDate: initial,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(
                            () => expCtrl.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expCtrl.text.isNotEmpty
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(DateTime.parse(expCtrl.text))
                                      : 'No expiration (Optional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: expCtrl.text.isNotEmpty
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: expCtrl.text.isNotEmpty
                                        ? AppColors.grey900
                                        : AppColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (expCtrl.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () =>
                                        setSheetState(() => expCtrl.clear()),
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: AppColors.grey400,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isPublic,
                          activeColor: AppColors.primary,
                          onChanged: (val) =>
                              setSheetState(() => isPublic = val ?? false),
                        ),
                        const Text(
                          'Public Document',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty ||
                              (!isEdit && selectedFile == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all required fields',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          try {
                            if (isEdit) {
                              await _repo.updateDocument(
                                item.id,
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty
                                    ? null
                                    : selectedDeptId,
                                isPublic: isPublic,
                                expiresAt: expCtrl.text.trim().isEmpty
                                    ? null
                                    : expCtrl.text.trim(),
                                filePath: selectedFile?.path,
                              );
                            } else {
                              await _repo.uploadDocument(
                                filePath: selectedFile!.path!,
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty
                                    ? null
                                    : selectedDeptId,
                                isPublic: isPublic,
                                expiresAt: expCtrl.text.trim().isEmpty
                                    ? null
                                    : expCtrl.text.trim(),
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          } catch (e) {
                            if (!mounted) return;
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          isEdit ? 'Update Document' : 'Upload Document',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
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

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.deleteDocument(id);
                _fetchData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String? mimeType) {
    if (mimeType == null) {
      return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
    }
    if (mimeType.contains('pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return const Icon(Icons.table_chart, color: Colors.green, size: 32);
    }
    if (mimeType.contains('image')) {
      return const Icon(Icons.image, color: Colors.blue, size: 32);
    }
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return const Icon(Icons.description, color: Colors.blueAccent, size: 32);
    }
    return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
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
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showForm(),
          ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Departments'),
                    ),
                    const DropdownMenuItem(
                      value: 'company-wide',
                      child: Text('Company-Wide'),
                    ),
                    ..._departments.map(
                      (d) => DropdownMenuItem(
                        value: d.id.toString(),
                        child: Text(d.name),
                      ),
                    ),
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
                ? const Center(
                    child: Text(
                      'No documents found.',
                      style: TextStyle(color: AppColors.grey500),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _documents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc = _documents[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFileIcon(doc.mimeType),
                                Icon(
                                  doc.isPublic ? Icons.public : Icons.lock,
                                  size: 16,
                                  color: doc.isPublic
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              doc.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (doc.fileName != null)
                              Text(
                                doc.fileName!,
                                style: const TextStyle(
                                  color: AppColors.grey500,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    doc.department?.name ?? 'Company-Wide',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                if (doc.expiresAt != null &&
                                    doc.expiresAt!.isNotEmpty)
                                  Builder(
                                    builder: (_) {
                                      final expDate = DateTime.tryParse(
                                        doc.expiresAt!,
                                      );
                                      final isExpired =
                                          expDate != null &&
                                          expDate.isBefore(DateTime.now());
                                      final formattedDate = expDate != null
                                          ? DateFormat(
                                              'dd MMM yyyy',
                                            ).format(expDate)
                                          : doc.expiresAt!;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isExpired
                                              ? AppColors.dangerLight
                                              : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isExpired
                                                ? AppColors.danger.withAlpha(50)
                                                : const Color(0xFFFDE68A),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isExpired
                                                  ? Icons.event_busy_rounded
                                                  : Icons
                                                        .event_available_rounded,
                                              size: 12,
                                              color: isExpired
                                                  ? AppColors.danger
                                                  : const Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isExpired
                                                  ? 'Expired ($formattedDate)'
                                                  : 'Expires: $formattedDate',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isExpired
                                                    ? AppColors.danger
                                                    : const Color(0xFFD97706),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                if (doc.fileSize != null)
                                  Text(
                                    '${(doc.fileSize! / 1024 / 1024).toStringAsFixed(1)} MB',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${doc.uploaderName ?? 'Unknown'} · ${doc.createdAt?.substring(0, 10) ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey400,
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showPreview(doc),
                                  icon: const Icon(
                                    Icons.visibility,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  label: const Text(
                                    'View',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _downloadFile(doc),
                                  icon: const Icon(
                                    Icons.download,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  label: const Text(
                                    'Download',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _showForm(doc),
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.grey600,
                                  ),
                                  label: const Text(
                                    'Edit',
                                    style: TextStyle(color: AppColors.grey600),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _confirmDelete(doc.id, doc.title),
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: AppColors.danger,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_lastPage > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing $_from-$_to of $_total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.grey600,
                        ),
                        onPressed: _currentPage > 1
                            ? () => _changePage(_currentPage - 1)
                            : null,
                      ),
                      Text(
                        '$_currentPage / $_lastPage',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.grey600,
                        ),
                        onPressed: _currentPage < _lastPage
                            ? () => _changePage(_currentPage + 1)
                            : null,
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
