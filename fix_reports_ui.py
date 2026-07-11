import re

with open('lib/pages/hr/admin_reports_screen.dart', 'r') as f:
    content = f.read()

# 1. Update _generate to call _showResultsSheet
old_generate = r"      final result = await AdminOperationsRepository\(\)\.generateReport\(type: type, params: params\);\n      setState\(\(\) \{ _result = result; _isLoading = false; \}\);"

new_generate = """      final result = await AdminOperationsRepository().generateReport(type: type, params: params);
      setState(() { _result = result; _isLoading = false; });
      if (mounted) _showResultsSheet(result, type);"""

content = re.sub(old_generate, new_generate, content)

# 2. Add _showResultsSheet and _buildRecordCard
new_methods = """
  void _showResultsSheet(Map<String, dynamic> data, String type) {
    final records = data['records'] as List<dynamic>? ?? [];
    final total = data['total'] ?? 0;
    
    final rType = _reportTypes.firstWhere((e) => e['key'] == type);
    final color = rType['color'] as Color;
    final label = rType['label'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                            child: Icon(rType['icon'] as IconData, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$label Report', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                              Text('Found $total records', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_isExporting)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            IconButton(
                              icon: const Icon(Icons.download, color: AppColors.primary),
                              onPressed: () async {
                                setSheetState(() => _isExporting = true);
                                await _export(type);
                                if (ctx.mounted) setSheetState(() => _isExporting = false);
                              },
                              tooltip: 'Export Report',
                            ),
                          IconButton(icon: const Icon(Icons.close, color: AppColors.grey500), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.grey200),
                Expanded(
                  child: records.isEmpty
                      ? const Center(child: Text('No records found for this period.', style: TextStyle(color: AppColors.grey500)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final record = records[i] as Map<String, dynamic>;
                            return _buildRecordCard(record, color);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record, Color themeColor) {
    // Try to extract a title from common fields
    String title = record['full_name'] ?? record['candidate_name'] ?? record['asset_name'] ?? record['title'] ?? 'Record';
    String? subtitle = record['emp_code'] ?? record['asset_code'] ?? record['period'] ?? record['job_title'] ?? record['category'];
    String? status = record['status'] ?? record['stage'];

    // Remove these from the generic list so we don't duplicate them
    final displayData = Map<String, dynamic>.from(record)
      ..removeWhere((k, v) => ['full_name', 'candidate_name', 'asset_name', 'title', 'emp_code', 'asset_code', 'period', 'job_title', 'category', 'status', 'stage'].contains(k));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(color: AppColors.grey200.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                      ]
                    ],
                  ),
                ),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: themeColor.withAlpha(26), borderRadius: BorderRadius.circular(20)),
                    child: Text(status.toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: themeColor)),
                  ),
              ],
            ),
          ),
          if (displayData.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.grey100),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.grey50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                children: displayData.entries.map((e) {
                  final key = e.key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
                  final val = e.value?.toString() ?? '-';
                  return SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(key, style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(val, style: const TextStyle(fontSize: 13, color: AppColors.grey800, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }
"""

content = re.sub(r'}\s*$', new_methods + '\n}', content)

with open('lib/pages/hr/admin_reports_screen.dart', 'w') as f:
    f.write(content)

