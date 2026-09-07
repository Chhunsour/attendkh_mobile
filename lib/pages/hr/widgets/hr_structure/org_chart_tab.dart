import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/hr_repository.dart';
import 'package:attendkh/services/network/dio_client.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Org Chart Tab ───────────────────────────────────────────────────────────
class OrgChartTab extends ConsumerStatefulWidget {
  const OrgChartTab({super.key});

  @override
  ConsumerState<OrgChartTab> createState() => _OrgChartTabState();
}

class _OrgChartTabState extends ConsumerState<OrgChartTab> {
  late TextEditingController _searchCtrl;
  final TransformationController _transformCtrl = TransformationController();
  String _searchQuery = '';
  int _maxDepth = 2;
  String _layoutMode = 'hybrid';
  final Set<int> _collapsedNodes = {};

  // Dept colors for visual grouping
  static const _deptColors = [
    Color(0xFFEFF6FF), // orange
    Color(0xFFEFF6FF), // blue
    Color(0xFFF5F3FF), // purple
    Color(0xFFECFDF5), // emerald
    Color(0xFFFDF2F8), // pink
  ];
  static const _deptDots = [
    Color(0xFF0052FF),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
  ];
  int _deptColorIdx = 0;
  final Map<String, int> _deptColorMap = {};

  Color _deptBg(String? deptName) {
    final key = deptName ?? '__none';
    if (!_deptColorMap.containsKey(key)) {
      _deptColorMap[key] = _deptColorIdx % _deptColors.length;
      _deptColorIdx++;
    }
    return _deptColors[_deptColorMap[key]!];
  }

  Color _deptDot(String? deptName) {
    final key = deptName ?? '__none';
    if (!_deptColorMap.containsKey(key)) {
      _deptColorMap[key] = _deptColorIdx % _deptDots.length;
      _deptColorIdx++;
    }
    return _deptDots[_deptColorMap[key]! % _deptDots.length];
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final matrix = _transformCtrl.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.2, 3.0);
    final actualFactor = targetScale / currentScale;
    // ignore: deprecated_member_use
    matrix.scale(actualFactor);
    _transformCtrl.value = matrix;
  }

  bool _nodeMatches(OrgNode node, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return node.name.toLowerCase().contains(q) ||
        (node.positionName?.toLowerCase().contains(q) ?? false) ||
        (node.departmentName?.toLowerCase().contains(q) ?? false);
  }

  bool _anyChildMatches(OrgNode node, String query) {
    if (query.isEmpty) return false;
    if (!node.hasSubordinates) return false;
    return node.subordinates!.any(
      (child) => _nodeMatches(child, query) || _anyChildMatches(child, query),
    );
  }

  Widget _buildNode(OrgNode node, int depth) {
    final deptBgColor = _deptBg(node.departmentName);
    final deptDotColor = _deptDot(node.departmentName);
    final match = _nodeMatches(node, _searchQuery);
    final childMatch = _anyChildMatches(node, _searchQuery);
    final shouldShow = _searchQuery.isEmpty || match || childMatch;
    final isManuallyCollapsed = _collapsedNodes.contains(node.id);
    final isExpanded =
        !isManuallyCollapsed && (depth < _maxDepth || _maxDepth == -1);

    if (!shouldShow) return const SizedBox.shrink();

    final statusColors = {
      'active': const Color(0xFF16A34A),
      'on_leave': const Color(0xFFD97706),
      'probation': const Color(0xFF2563EB),
      'resigned': const Color(0xFFDC2626),
      'terminated': const Color(0xFFDC2626),
    };
    final statusColor =
        statusColors[node.employmentStatus] ?? AppColors.grey500;

    final nodeCard = Container(
      width: 280, // Fixed width for nodes to align nicely
      decoration: BoxDecoration(
        color: deptBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: deptBgColor.withAlpha(180), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dept band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(150),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: deptDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.departmentName ?? '—',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF374151), Color(0xFF111827)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        image: node.photo != null && node.photo!.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  node.photo!.startsWith('http')
                                      ? node.photo!
                                      : '${DioClient.storageUrl}/${node.photo!.startsWith('/') ? node.photo!.substring(1) : node.photo!}',
                                  maxWidth: 120,
                                  maxHeight: 120,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: node.photo == null || node.photo!.isEmpty
                          ? Center(
                              child: Text(
                                node.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: deptDotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.positionName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          node.positionName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          node.employmentStatus
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Children count
                if (node.hasSubordinates)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      '${node.subordinatesCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                if (node.email != null && node.email!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('mailto:${node.email}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.mail_outline_rounded,
                        size: 14,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                if (node.phone != null && node.phone!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('tel:${node.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/employee/${node.id}');
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey400,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 10,
                        color: AppColors.grey400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Expand/Collapse button
          if (node.hasSubordinates)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_collapsedNodes.contains(node.id)) {
                      _collapsedNodes.remove(node.id);
                    } else {
                      _collapsedNodes.add(node.id);
                    }
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.expand_more_rounded
                            : Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.grey500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${node.subordinatesCount} ${node.subordinatesCount != 1 ? "reports" : "report"}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!node.hasSubordinates || !isExpanded) {
      if (depth == 0) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: nodeCard,
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: nodeCard,
      );
    }

    if (depth == 0 && _layoutMode == 'hybrid') {
      // Horizontal layout for root's children
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          nodeCard,
          Container(width: 2, height: 32, color: AppColors.grey300),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: node.subordinates!.map((child) {
              final isFirst = child == node.subordinates!.first;
              final isLast = child == node.subordinates!.last;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Horizontal connector
                  Row(
                    children: [
                      Container(
                        width: 156, // Half of 280 + 16 margin
                        height: 2,
                        color: isFirst ? Colors.transparent : AppColors.grey300,
                      ),
                      Container(
                        width: 156,
                        height: 2,
                        color: isLast ? Colors.transparent : AppColors.grey300,
                      ),
                    ],
                  ),
                  Container(width: 2, height: 16, color: AppColors.grey300),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildNode(child, depth + 1),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      );
    }

    // Vertical layout for teams
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nodeCard,
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.subordinates!.map((child) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.grey300, width: 2),
                          bottom: BorderSide(
                            color: AppColors.grey300,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildNode(child, depth + 1),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  int _countNodes(List<OrgNode> nodes) {
    int c = nodes.length;
    for (final n in nodes) {
      if (n.hasSubordinates) c += _countNodes(n.subordinates!);
    }
    return c;
  }

  int _maxTreeDepth(List<OrgNode> nodes, int d) {
    if (nodes.isEmpty) return d;
    int maxD = d + 1;
    for (final n in nodes) {
      if (n.hasSubordinates) {
        final cd = _maxTreeDepth(n.subordinates!, d + 1);
        if (cd > maxD) maxD = cd;
      }
    }
    return maxD;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orgChartAsync = ref.watch(orgChartProvider);

    return orgChartAsync.when(
      data: (tree) {
        if (tree.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_tree_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noOrgChartTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.noOrgChartDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final totalCount = _countNodes(tree);
        final maxDepthVal = _maxTreeDepth(tree, 0);

        return Column(
          children: [
            // Search + Depth
            Container(
              color: AppColors.surface(context),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(
                        () => _searchQuery = val.trim().toLowerCase(),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.searchOrgChartHint,
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.grey400,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.grey200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Depth control + stats
                  Row(
                    children: [
                      // Stats
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Text(
                          l10n.orgChartStats(totalCount, maxDepthVal),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Layout Toggle
                      Container(
                        height: 34,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _layoutMode = 'hybrid'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _layoutMode == 'hybrid'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _layoutMode == 'hybrid'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(10),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.account_tree_rounded,
                                  size: 16,
                                  color: _layoutMode == 'hybrid'
                                      ? AppColors.primary
                                      : AppColors.grey400,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _layoutMode = 'vertical'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _layoutMode == 'vertical'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _layoutMode == 'vertical'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(10),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.format_list_bulleted_rounded,
                                  size: 16,
                                  color: _layoutMode == 'vertical'
                                      ? AppColors.primary
                                      : AppColors.grey400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Depth Dropdown
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _maxDepth,
                            icon: const Icon(
                              Icons.unfold_more_rounded,
                              size: 16,
                              color: AppColors.grey500,
                            ),
                            iconSize: 16,
                            elevation: 4,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            isDense: true,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() => _maxDepth = newValue);
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: -1,
                                child: Text(l10n.expandAll),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text(l10n.showLevel1),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(l10n.showLevel2),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(l10n.showLevel3),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text(l10n.showLevel4),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text(l10n.showLevel5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grey200),
            // Tree
            Expanded(
              child: Container(
                color: const Color(
                  0xFFF1F5F9,
                ), // Slight gray background for contrast
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformCtrl,
                      minScale: 0.2,
                      maxScale: 3.0,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(
                        500,
                      ), // Lots of pan room
                      child: Padding(
                        padding: const EdgeInsets.all(64.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: tree
                              .map((root) => _buildNode(root, 0))
                              .toList(),
                        ),
                      ),
                    ),
                    // Legend
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Levels',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grey400,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...[
                              'C-Level',
                              'Director',
                              'Manager',
                              'Lead',
                              'Staff',
                            ].asMap().entries.map((entry) {
                              final i = entry.key;
                              final label = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _deptDots[i % _deptDots.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoomIn',
                            onPressed: () => _zoom(1.3),
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.grey700,
                            child: const Icon(Icons.add_rounded),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoomOut',
                            onPressed: () => _zoom(1 / 1.3),
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.grey700,
                            child: const Icon(Icons.remove_rounded),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoomReset',
                            onPressed: () =>
                                _transformCtrl.value = Matrix4.identity(),
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.grey700,
                            child: const Icon(
                              Icons.center_focus_strong_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => LoadingIndicator(message: l10n.loadingOrgChart),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.danger,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.failedToLoadOrgChart,
              style: const TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(orgChartProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
