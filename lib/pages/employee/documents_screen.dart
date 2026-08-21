import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final employeeDocumentsProvider =
    FutureProvider.autoDispose<List<DocumentData>>((ref) async {
  final repo = DocumentsRepository();
  return repo.getEmployeeDocuments();
});

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _search = '';
  String _filterType = 'all';
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<int> _downloadingIds = <int>{};
  final DocumentsRepository _repo = DocumentsRepository();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_rounded;
    if (mimeType.contains('image/')) return Icons.image_rounded;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('csv')) {
      return Icons.table_chart_rounded;
    }
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description_rounded;
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('archive') ||
        mimeType.contains('rar')) {
      return Icons.folder_zip_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getIconColor(String? mimeType) {
    if (mimeType == null) return AppColors.primary;
    if (mimeType.contains('image/')) return const Color(0xFF8B5CF6);
    if (mimeType.contains('pdf')) return const Color(0xFFEF4444);
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('csv')) {
      return const Color(0xFF10B981);
    }
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return const Color(0xFF2563EB);
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('archive') ||
        mimeType.contains('rar')) {
      return const Color(0xFFF59E0B);
    }
    return AppColors.primary;
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes == 0) return '0 Bytes';
    const k = 1024;
    final sizes = ['Bytes', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= k && i < sizes.length - 1) {
      size /= k;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${sizes[i]}';
  }

  Future<void> _downloadAndOpenFile(
    BuildContext context,
    DocumentData doc,
    AppLocalizations l10n,
  ) async {
    if (_downloadingIds.contains(doc.id)) return;

    HapticFeedback.lightImpact();
    setState(() => _downloadingIds.add(doc.id));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${l10n.downloadStarted}: ${doc.fileName ?? doc.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final rawName = doc.fileName ?? doc.title;
      // Sanitize filename to avoid path issues
      final safeName = rawName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final savePath = '${tempDir.path}/$safeName';

      await _repo.downloadDocument(
        doc.id,
        savePath,
        downloadUrl: doc.downloadUrl,
      );

      if (mounted) {
        final result = await OpenFilex.open(savePath);
        if (result.type != ResultType.done &&
            result.type != ResultType.noAppToOpen &&
            context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open file: ${result.message}'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Failed to download document', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToDownloadDoc}$e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(doc.id));
      }
    }
  }

  void _showPreviewSheet(
    BuildContext context,
    DocumentData doc,
    bool isDark,
    AppLocalizations l10n,
  ) {
    HapticFeedback.selectionClick();
    final isImage = doc.mimeType?.contains('image/') ?? false;
    final color = _getIconColor(doc.mimeType);
    final icon = _getFileIcon(doc.mimeType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final isDownloading = _downloadingIds.contains(doc.id);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.grey700 : AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(
                                alpha: isDark ? 0.40 : 0.25,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.grey900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (doc.fileName != null &&
                                  doc.fileName != doc.title) ...[
                                const SizedBox(height: 2),
                                Text(
                                  doc.fileName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.grey400
                                        : AppColors.grey500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image preview container if image & URL available
                          if (isImage &&
                              doc.downloadUrl != null &&
                              doc.downloadUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 260),
                                width: double.infinity,
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                child: CachedNetworkImage(
                                  imageUrl: doc.downloadUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.broken_image_rounded,
                                            size: 40,
                                            color: isDark
                                                ? AppColors.grey600
                                                : AppColors.grey400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Preview not available',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.grey500
                                                  : AppColors.grey400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          if (doc.description != null &&
                              doc.description!.isNotEmpty) ...[
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doc.description!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.grey900,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          _buildMetadataRow(
                            'Department',
                            doc.department?.name ?? 'Company-Wide',
                            isDark,
                          ),
                          _buildMetadataRow(
                            'File Size',
                            _formatBytes(doc.fileSize),
                            isDark,
                          ),
                          if (doc.createdAt != null &&
                              doc.createdAt!.length >= 10)
                            _buildMetadataRow(
                              'Uploaded',
                              doc.createdAt!.substring(0, 10),
                              isDark,
                            ),
                          if (doc.uploaderName != null &&
                              doc.uploaderName!.isNotEmpty)
                            _buildMetadataRow(
                              'Uploaded By',
                              doc.uploaderName!,
                              isDark,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.paddingOf(ctx).bottom + 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isDownloading
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                await _downloadAndOpenFile(
                                  context,
                                  doc,
                                  l10n,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.file_open_rounded,
                                size: 20,
                              ),
                        label: Text(
                          isDownloading
                              ? 'Opening...'
                              : 'Open & View Document',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetadataRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(employeeDocumentsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            // ── AttendKH Gradient Hero Header ──
            _buildHeroHeader(context, isDark, l10n),

            // ── Documents Body ──
            Expanded(
              child: docsAsync.when(
                loading: () => Center(
                  child: LoadingIndicator(message: l10n.loading),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load documents: $err',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(employeeDocumentsProvider),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (documents) {
                  final filtered = documents.where((d) {
                    if (_search.isNotEmpty) {
                      final q = _search.toLowerCase();
                      final matchesTitle = d.title.toLowerCase().contains(q);
                      final matchesDesc =
                          d.description?.toLowerCase().contains(q) ?? false;
                      if (!matchesTitle && !matchesDesc) return false;
                    }

                    if (_filterType == 'pdf') {
                      return d.mimeType?.contains('pdf') ?? false;
                    }
                    if (_filterType == 'docs') {
                      return (d.mimeType?.contains('word') ?? false) ||
                          (d.mimeType?.contains('document') ?? false);
                    }
                    if (_filterType == 'sheets') {
                      return (d.mimeType?.contains('sheet') ?? false) ||
                          (d.mimeType?.contains('excel') ?? false);
                    }
                    if (_filterType == 'images') {
                      return d.mimeType?.contains('image/') ?? false;
                    }
                    return true;
                  }).toList();

                  final Color cardBg =
                      isDark ? const Color(0xFF1E293B) : Colors.white;
                  final Color cardBorder = isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0);

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(employeeDocumentsProvider),
                    color: AppColors.primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Search Bar ──
                                Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.02,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (val) =>
                                        setState(() => _search = val.trim()),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.grey900,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: l10n.searchFilesHint,
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? AppColors.grey500
                                            : AppColors.grey400,
                                        fontSize: 13,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: isDark
                                            ? AppColors.grey400
                                            : AppColors.grey400,
                                        size: 20,
                                      ),
                                      suffixIcon: _search.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear_rounded,
                                                color: isDark
                                                    ? AppColors.grey400
                                                    : AppColors.grey400,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(() => _search = '');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // ── Senior File Filter Chips ──
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildSeniorFilterChip(
                                        l10n.allFiles,
                                        'all',
                                        isDark,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSeniorFilterChip(
                                        'PDFs',
                                        'pdf',
                                        isDark,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSeniorFilterChip(
                                        l10n.wordDocuments,
                                        'docs',
                                        isDark,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSeniorFilterChip(
                                        l10n.spreadsheets,
                                        'sheets',
                                        isDark,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSeniorFilterChip(
                                        l10n.images,
                                        'images',
                                        isDark,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // ── Section Header ──
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l10n.availableFiles,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.grey900,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF3B82F6)
                                                    .withValues(alpha: 0.3)
                                                : const Color(0xFFBFDBFE),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          '${filtered.length} ${l10n.documentsCount}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFF93C5FD)
                                                : AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),

                        // ── Lazy Virtualized Documents List ──
                        if (filtered.isEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            sliver: SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.folder_off_rounded,
                                      size: 48,
                                      color: AppColors.grey300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _search.isNotEmpty
                                          ? '${l10n.noFilesMatching} "$_search"'
                                          : l10n.noDocumentsAvailable,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.grey400
                                            : AppColors.grey600,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            sliver: SliverList.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final doc = filtered[index];
                                final color = _getIconColor(doc.mimeType);
                                final icon = _getFileIcon(doc.mimeType);
                                final isDownloading =
                                    _downloadingIds.contains(doc.id);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(18),
                                    child: InkWell(
                                      onTap: () => _showPreviewSheet(
                                        context,
                                        doc,
                                        isDark,
                                        l10n,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border:
                                              Border.all(color: cardBorder),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: isDark ? 0.2 : 0.02,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha:
                                                      isDark ? 0.18 : 0.10,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: color.withValues(
                                                    alpha:
                                                        isDark ? 0.35 : 0.20,
                                                  ),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Icon(
                                                icon,
                                                color: color,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    doc.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: true,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                      color: isDark
                                                          ? Colors.white
                                                          : AppColors.grey900,
                                                      letterSpacing: -0.1,
                                                    ),
                                                  ),
                                                  if (doc.description != null &&
                                                      doc.description!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      doc.description!,
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? AppColors.grey400
                                                            : AppColors.grey500,
                                                        fontSize: 12,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 7,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF0F172A)
                                                              : const Color(
                                                                  0xFFF1F5F9),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF334155)
                                                                : const Color(
                                                                    0xFFE2E8F0),
                                                            width: 0.8,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          _formatBytes(
                                                              doc.fileSize),
                                                          style: TextStyle(
                                                            fontSize: 10.5,
                                                            color: isDark
                                                                ? AppColors
                                                                    .grey300
                                                                : AppColors
                                                                    .grey700,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      if (doc.department !=
                                                          null) ...[
                                                        const SizedBox(
                                                            width: 6),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 7,
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF1E293B)
                                                                : const Color(
                                                                    0xFFEFF6FF),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            border: Border.all(
                                                              color: isDark
                                                                  ? const Color(
                                                                          0xFF3B82F6)
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      )
                                                                  : const Color(
                                                                      0xFFBFDBFE),
                                                              width: 0.8,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            doc.department!
                                                                .name,
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isDark
                                                                  ? const Color(
                                                                      0xFF93C5FD)
                                                                  : AppColors
                                                                      .primary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: isDownloading
                                                    ? null
                                                    : () =>
                                                        _downloadAndOpenFile(
                                                          context,
                                                          doc,
                                                          l10n,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF0F172A)
                                                        : const Color(
                                                            0xFFEFF6FF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? const Color(
                                                                  0xFF3B82F6)
                                                              .withValues(
                                                              alpha: 0.3)
                                                          : const Color(
                                                              0xFFBFDBFE),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: isDownloading
                                                      ? const Center(
                                                          child: SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons
                                                              .download_rounded,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF93C5FD)
                                                              : AppColors
                                                                  .primary,
                                                          size: 19,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, AppColors.primary, 0.6)!],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient rings
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 6,
              16,
              22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Row
                Row(
                  children: [
                    _heroIconButton(
                      Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.companyDocuments,
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.corporateDocVaultSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xB3FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _heroIconButton(
                      Icons.refresh_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.invalidate(employeeDocumentsProvider);
                      },
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

  Widget _heroIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }

  Widget _buildSeniorFilterChip(String label, String type, bool isDark) {
    final isSelected = _filterType == type;

    final Color chipBg = isSelected
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final Color chipBorder = isSelected
        ? (isDark ? const Color(0xFF3B82F6) : AppColors.primary)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final Color chipTextColor = isSelected
        ? (isDark ? const Color(0xFF93C5FD) : AppColors.primary)
        : (isDark ? AppColors.grey400 : AppColors.grey600);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterType = type);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chipBorder,
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.20 : 0.08,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: chipTextColor,
          ),
        ),
      ),
    );
  }
}
