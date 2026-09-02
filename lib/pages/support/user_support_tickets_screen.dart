// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/services/user_support_tickets_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

final userSupportTicketsProvider =
    FutureProvider.autoDispose<List<UserSupportTicket>>((ref) {
  return UserSupportTicketsRepository().getTickets();
});

class UserSupportTicketsScreen extends ConsumerStatefulWidget {
  const UserSupportTicketsScreen({super.key});

  @override
  ConsumerState<UserSupportTicketsScreen> createState() =>
      _UserSupportTicketsScreenState();
}

class _UserSupportTicketsScreenState
    extends ConsumerState<UserSupportTicketsScreen> {
  int? _expandedId;

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

  static const _priorityColors = {
    'low': Color(0xFF64748B),
    'medium': Color(0xFF0EA5E9),
    'high': Color(0xFFF59E0B),
    'urgent': Color(0xFFEF4444),
  };

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'open':
        return l10n.ticketStatusOpen;
      case 'in_progress':
        return l10n.ticketStatusInProgress;
      case 'resolved':
        return l10n.ticketStatusResolved;
      case 'closed':
        return l10n.ticketStatusClosed;
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getPriorityLabel(String priority, AppLocalizations l10n) {
    switch (priority.toLowerCase()) {
      case 'low':
        return l10n.ticketPriorityLow;
      case 'medium':
        return l10n.ticketPriorityMedium;
      case 'high':
        return l10n.ticketPriorityHigh;
      case 'urgent':
        return l10n.ticketPriorityUrgent;
      default:
        return priority.toUpperCase();
    }
  }

  void _openCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateTicketBottomSheet(),
    ).then((val) {
      if (val == true) {
        ref.invalidate(userSupportTicketsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ticketsAsync = ref.watch(userSupportTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.helpSupportDesk,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(userSupportTicketsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateBottomSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.submitTicket, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(userSupportTicketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text('${l10n.failedToLoadTickets}: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(userSupportTicketsProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (tickets) => _buildBody(tickets, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(List<UserSupportTicket> tickets, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Top banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.directSupportChannel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.directSupportChannelDesc,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (tickets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.grey400),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noSupportTicketsYet,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.noSupportTicketsDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Text(
            '${l10n.mySupportRequests} (${tickets.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          ...tickets.map((t) => _buildTicketCard(t, l10n)),
        ],
      ],
    );
  }

  Widget _buildTicketCard(UserSupportTicket ticket, AppLocalizations l10n) {
    final isExpanded = _expandedId == ticket.id;
    final status = ticket.status.toLowerCase();
    final priority = ticket.priority.toLowerCase();
    final statusColor = _statusColors[status] ?? AppColors.grey600;
    final statusBg = _statusBgs[status] ?? AppColors.grey100;
    final priorityColor = _priorityColors[priority] ?? AppColors.grey600;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border(context),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expandedId = isExpanded ? null : ticket.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${ticket.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getPriorityLabel(priority, l10n),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(status, l10n),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.subject,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.createdAt.isNotEmpty
                      ? ticket.createdAt.replaceFirst('T', ' ').substring(0, 16)
                      : '-',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                ),
                if (isExpanded) ...[
                  const Divider(height: 20),
                  Text(
                    '${l10n.trainingDescription}:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.message,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTicketBottomSheet extends StatefulWidget {
  const _CreateTicketBottomSheet();

  @override
  State<_CreateTicketBottomSheet> createState() =>
      _CreateTicketBottomSheetState();
}

class _CreateTicketBottomSheetState extends State<_CreateTicketBottomSheet> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _priority = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AppLocalizations l10n) async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterSubjectAndMessage),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await UserSupportTicketsRepository().createTicket(
        subject: subject,
        message: message,
        priority: _priority,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.ticketSubmittedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToLoadTickets}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
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
              children: [
                const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.submitSupportTicketTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject
            Text(
              l10n.subjectSummaryLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                hintText: l10n.subjectHint,
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                filled: true,
                fillColor: AppColors.bg(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Priority
            Text(
              l10n.priority,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _priority,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'low', child: Text(l10n.lowPriorityDesc)),
                    DropdownMenuItem(value: 'medium', child: Text(l10n.mediumPriorityDesc)),
                    DropdownMenuItem(value: 'high', child: Text(l10n.highPriorityDesc)),
                    DropdownMenuItem(value: 'urgent', child: Text(l10n.urgentPriorityDesc)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              l10n.detailedDescriptionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.detailedDescriptionHint,
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                filled: true,
                fillColor: AppColors.bg(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : () => _handleSubmit(l10n),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_submitting ? l10n.submittingTicket : l10n.sendTicketToSuperAdmin),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
