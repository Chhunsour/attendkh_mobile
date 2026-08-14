// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_support_tickets_repository.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final adminSupportTicketsProvider =
    FutureProvider.autoDispose<List<AdminSupportTicket>>((ref) {
      return AdminSupportTicketsRepository().getTickets();
    });

class AdminSupportTicketsScreen extends ConsumerStatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  ConsumerState<AdminSupportTicketsScreen> createState() =>
      _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState
    extends ConsumerState<AdminSupportTicketsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _statusColors = {
    'open': Color(0xFFF59E0B),
    'in_progress': Color(0xFF6366F1),
    'resolved': Color(0xFF10B981),
    'closed': Color(0xFF64748B),
  };

  static const _statusBgs = {
    'open': Color(0xFFFFFBEB),
    'in_progress': Color(0xFFEEF2FF),
    'resolved': Color(0xFFECFDF5),
    'closed': Color(0xFFF1F5F9),
  };

  static const _statusIcons = {
    'open': Icons.hourglass_empty_rounded,
    'in_progress': Icons.sync_rounded,
    'resolved': Icons.check_circle_outline_rounded,
    'closed': Icons.check_circle_rounded,
  };

  static const _priorityColors = {
    'low': Color(0xFF64748B),
    'medium': Color(0xFF0EA5E9),
    'high': Color(0xFFF59E0B),
    'urgent': Color(0xFFEF4444),
  };

  static const _priorityBgs = {
    'low': Color(0xFFF1F5F9),
    'medium': Color(0xFFF0F9FF),
    'high': Color(0xFFFFFBEB),
    'urgent': Color(0xFFFEF2F2),
  };

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(adminSupportTicketsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.supportTicketsTitle,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminSupportTicketsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminSupportTicketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(err, l10n),
          data: (tickets) => _buildContent(tickets, l10n),
        ),
      ),
    );
  }

  Widget _buildError(Object err, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadTickets,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminSupportTicketsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
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
    );
  }

  Widget _buildContent(List<AdminSupportTicket> tickets, AppLocalizations l10n) {
    final openCount = tickets.where((t) => t.status == 'open').length;
    final inProgressCount = tickets.where((t) => t.status == 'in_progress').length;
    final resolvedCount = tickets.where((t) => t.status == 'resolved' || t.status == 'closed').length;

    var filtered = tickets.where((t) {
      final matchesSearch =
          _searchTerm.isEmpty ||
          t.subject.toLowerCase().contains(_searchTerm) ||
          (t.message?.toLowerCase().contains(_searchTerm) ?? false) ||
          (t.userName?.toLowerCase().contains(_searchTerm) ?? false) ||
          (t.companyName?.toLowerCase().contains(_searchTerm) ?? false);
      final matchesStatus = _statusFilter == 'all' || t.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Overview Metric Snapshot ──
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Tickets',
                value: '${tickets.length}',
                icon: Icons.confirmation_number_rounded,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Open',
                value: '$openCount',
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Progress',
                value: '$inProgressCount',
                icon: Icons.sync_rounded,
                color: const Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Resolved',
                value: '$resolvedCount',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Search Field ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchTerm = val.trim().toLowerCase()),
            style: const TextStyle(fontSize: 13.5, color: AppColors.grey900),
            decoration: InputDecoration(
              hintText: 'Search subject, requester, company...',
              hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 18),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.grey400, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchTerm = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Status Filter Chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All (${tickets.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Open ($openCount)', 'open'),
              const SizedBox(width: 8),
              _buildFilterChip('In Progress ($inProgressCount)', 'in_progress'),
              const SizedBox(width: 8),
              _buildFilterChip('Resolved ($resolvedCount)', 'resolved'),
              const SizedBox(width: 8),
              _buildFilterChip('Closed', 'closed'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Ticket Cards ──
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.support_agent_outlined, size: 48, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text(
                  _searchTerm.isNotEmpty ? 'No tickets matching "$_searchTerm"' : l10n.noSupportTickets,
                  style: const TextStyle(color: AppColors.grey600, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filtered.map((ticket) => _buildTicketCard(ticket, l10n)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(AdminSupportTicket ticket, AppLocalizations l10n) {
    final statusColor = _statusColors[ticket.status] ?? AppColors.grey600;
    final statusBg = _statusBgs[ticket.status] ?? AppColors.grey100;
    final statusIcon = _statusIcons[ticket.status] ?? Icons.help_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTicketDetail(ticket, l10n),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              ticket.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: AppColors.grey900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 5, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  _formatStatus(ticket.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (ticket.message != null && ticket.message!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ticket.message!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (ticket.userName != null) ...[
                            const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.grey500),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                ticket.userName!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (ticket.companyName != null) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: AppColors.grey400, fontSize: 11)),
                            const SizedBox(width: 6),
                            const Icon(Icons.business_rounded, size: 12, color: AppColors.grey500),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                ticket.companyName!,
                                style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (ticket.priority != null && ticket.priority!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _priorityBgs[ticket.priority] ?? AppColors.grey100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ticket.priority!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: _priorityColors[ticket.priority] ?? AppColors.grey600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());
  }

  void _showTicketDetail(AdminSupportTicket ticket, AppLocalizations l10n) {
    String selectedStatus = ticket.status;
    String selectedPriority = ticket.priority ?? 'medium';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Ticket #${ticket.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.grey500),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  if (ticket.message != null && ticket.message!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Text(
                        ticket.message!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (ticket.userName != null || ticket.companyName != null)
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        Text(
                          [
                            if (ticket.userName != null) ticket.userName!,
                            if (ticket.companyName != null) '(${ticket.companyName!})',
                          ].join(' '),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey800),
                        ),
                        if (ticket.createdAt != null) ...[
                          const Spacer(),
                          Text(
                            _formatDate(ticket.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.grey400),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 18),

                  // Status dropdown
                  const Text(
                    'Ticket Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => selectedStatus = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Priority dropdown
                  const Text(
                    'Priority Level',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => selectedPriority = v);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Cancel + Update buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setState(() => isSaving = true);
                                    try {
                                      await AdminSupportTicketsRepository()
                                          .updateTicket(ticket.id, {
                                            'status': selectedStatus,
                                            'priority': selectedPriority,
                                          });
                                      ref.invalidate(adminSupportTicketsProvider);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Ticket updated successfully'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed: $e'),
                                            backgroundColor: AppColors.danger,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Update Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
