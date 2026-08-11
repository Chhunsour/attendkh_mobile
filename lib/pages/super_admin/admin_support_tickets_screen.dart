import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_support_tickets_repository.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final adminSupportTicketsProvider =
    FutureProvider.autoDispose<List<AdminSupportTicket>>((ref) {
  return AdminSupportTicketsRepository().getTickets();
});

class AdminSupportTicketsScreen extends ConsumerWidget {
  const AdminSupportTicketsScreen({super.key});

  static const _statusColors = {
    'open': AppColors.warning,
    'in_progress': AppColors.primary,
    'resolved': AppColors.success,
    'closed': AppColors.success,
  };

  static const _statusBgs = {
    'open': AppColors.warningLight,
    'in_progress': AppColors.primaryLight,
    'resolved': AppColors.successLight,
    'closed': AppColors.successLight,
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.supportTicketsTitle,
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminSupportTicketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(context, err, ref, l10n),
          data: (tickets) => _buildList(context, ref, tickets, l10n),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object err, WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(l10n.failedToLoadTickets,
                style: const TextStyle(
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
              label: Text(l10n.retry),
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
      List<AdminSupportTicket> tickets, AppLocalizations l10n) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent_rounded,
                size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(l10n.noSupportTickets,
                style: const TextStyle(
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
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey900.withAlpha(10),
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
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.grey400, size: 20),
                  onSelected: (action) =>
                      _updateTicketStatus(context, ref, ticket, action, l10n),
                  itemBuilder: (_) => [
                    if (ticket.status != 'in_progress')
                      PopupMenuItem(
                        value: 'in_progress',
                        child: Row(children: [
                          const Icon(Icons.sync_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(l10n.markInProgress)
                        ]),
                      ),
                    if (ticket.status != 'resolved')
                      PopupMenuItem(
                        value: 'resolved',
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(l10n.markResolved)
                        ]),
                      ),
                    if (ticket.status != 'closed')
                      PopupMenuItem(
                        value: 'closed',
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(l10n.closeTicket)
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
    AppLocalizations l10n,
  ) async {
    try {
      await AdminSupportTicketsRepository()
          .updateTicket(ticket.id, {'status': newStatus});
      ref.invalidate(adminSupportTicketsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                l10n.ticketMarkedAs(ticket.id, _formatStatus(newStatus))),
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