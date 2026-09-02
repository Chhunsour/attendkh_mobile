import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class ScheduleInterviewSheet extends ConsumerStatefulWidget {
  final int jobId;
  final int candidateId;

  const ScheduleInterviewSheet({
    super.key,
    required this.jobId,
    required this.candidateId,
  });

  @override
  ConsumerState<ScheduleInterviewSheet> createState() => _ScheduleInterviewSheetState();
}

class _ScheduleInterviewSheetState extends ConsumerState<ScheduleInterviewSheet> {
  String selType = 'phone';
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final durationCtrl = TextEditingController(text: '30');
  final locationCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    dateCtrl.dispose();
    timeCtrl.dispose();
    durationCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.grey600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context).withAlpha(120)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context).withAlpha(120)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.scheduleInterview,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selType,
              decoration: _inputDecor('Interview Type'),
              items: [
                DropdownMenuItem(value: 'phone', child: Text(l10n.phoneInterview)),
                const DropdownMenuItem(value: 'video', child: Text('Video Conference')),
                const DropdownMenuItem(value: 'in_person', child: Text('In Person')),
                DropdownMenuItem(value: 'technical', child: Text(l10n.technicalAssessment)),
              ],
              onChanged: (val) => setState(() => selType = val ?? 'phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: _inputDecor('Date *').copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.grey500),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dateCtrl.text = date.toIso8601String().split('T')[0];
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              readOnly: true,
              decoration: _inputDecor('Time *').copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.grey500),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      timeCtrl.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecor('Duration (minutes)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationCtrl,
              decoration: _inputDecor('Location / Meeting Link'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (dateCtrl.text.isEmpty || timeCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.dateTimeRequired)),
                        );
                        return;
                      }
                      setState(() => _isSubmitting = true);
                      final data = <String, dynamic>{
                        'type': selType,
                        'scheduled_at': '${dateCtrl.text} ${timeCtrl.text}',
                        'duration_minutes': int.tryParse(durationCtrl.text) ?? 30,
                        if (locationCtrl.text.isNotEmpty) 'location': locationCtrl.text,
                      };
                      try {
                        await RecruitmentRepository().scheduleInterview(widget.candidateId, data);
                        ref.invalidate(jobCandidatesProvider(widget.jobId));
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      l10n.confirmSchedule,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}