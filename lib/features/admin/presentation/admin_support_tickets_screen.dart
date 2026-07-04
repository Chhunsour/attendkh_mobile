import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/admin/data/admin_support_tickets_repository.dart';

final adminSupportTicketsProvider =
    FutureProvider.autoDispose<List<AdminSupportTicket>>((ref) {
  return AdminSupportTicketsRepository().getTickets();
});

class AdminSupportTicketsScreen extends ConsumerWidget {
  const AdminSupportTicketsScreen({super.key});

  static const _statusColors = {
    'open': Color(0xFFF59E0B),
    'in_progress': Color(0xFF3B82F6),
    'resolved': Color(0xFF10B981),
    'closed': Color(0xFF10B981),
  };

  static const _statusBgs = {
    'open': Color(0xFFFFFBEB),
    'in_progress': Color(0xFFEFF6FF),
    'resolved': Color(0xFFECFDF5),
    'closed': Color(0xFFECFDF5),
  };

  static const _statusIcons = {
    'open': Icons.hourglass_empty_rounded,
    'in_progress': Icons.sync_rounded,
    'resolved': Icons.check_circle_outline_rounded,
    'closed': Icons.check_circle_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(adminSupportTicketsProvider);

    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Support Tickets',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(adminSupportTicketsProvider),
            child: ticketsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => _buildError(context, err, ref),
              data: (tickets) => _buildList(context, ref, tickets),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object err, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load tickets',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: TextStyle(fontSize: 12, color: AppColors.grey500),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminSupportTicketsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref,
      List<AdminSupportTicket> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_rounded,
                size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text('No support tickets',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final statusColor =
            _statusColors[ticket.status] ?? AppColors.grey400;
        final statusBg = _statusBgs[ticket.status] ?? AppColors.grey100;
        final statusIcon =
            _statusIcons[ticket.status] ?? Icons.help_outline_rounded;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (ticket.userName != null) ticket.userName!,
                          if (ticket.companyName != null)
                            '(${ticket.companyName!})',
                        ].join(' '),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatStatus(ticket.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded,
                      color: AppColors.grey400, size: 20),
                  onSelected: (action) =>
                      _updateTicketStatus(context, ref, ticket, action),
                  itemBuilder: (_) => [
                    if (ticket.status != 'in_progress')
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Row(children: [
                          Icon(Icons.sync_rounded,
                              size: 18, color: Color(0xFF3B82F6)),
                          SizedBox(width: 8),
                          Text('Mark In Progress')
                        ]),
                      ),
                    if (ticket.status != 'resolved')
                      const PopupMenuItem(
                        value: 'resolved',
                        child: Row(children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('Mark Resolved')
                        ]),
                      ),
                    if (ticket.status != 'closed')
                      const PopupMenuItem(
                        value: 'closed',
                        child: Row(children: [
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('Close Ticket')
                        ]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'\b\w'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }

  Future<void> _updateTicketStatus(
    BuildContext context,
    WidgetRef ref,
    AdminSupportTicket ticket,
    String newStatus,
  ) async {
    try {
      await AdminSupportTicketsRepository()
          .updateTicket(ticket.id, {'status': newStatus});
      ref.invalidate(adminSupportTicketsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ticket #${ticket.id} marked as ${_formatStatus(newStatus)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}