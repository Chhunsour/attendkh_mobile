// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class AddCandidateSheet extends ConsumerStatefulWidget {
  final int jobId;

  const AddCandidateSheet({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<AddCandidateSheet> createState() => _AddCandidateSheetState();
}

class _AddCandidateSheetState extends ConsumerState<AddCandidateSheet> {
  final fullNameCtrl = TextEditingController();
  final nameKhCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final expCtrl = TextEditingController();
  final currentPositionCtrl = TextEditingController();
  final currentCompanyCtrl = TextEditingController();
  final expectedSalaryCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    fullNameCtrl.dispose();
    nameKhCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    expCtrl.dispose();
    currentPositionCtrl.dispose();
    currentCompanyCtrl.dispose();
    expectedSalaryCtrl.dispose();
    notesCtrl.dispose();
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
                  'Add Candidate',
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
            TextField(
              controller: fullNameCtrl,
              decoration: _inputDecor('Full Name (English) *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameKhCtrl,
              decoration: _inputDecor('Name (Khmer) *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecor('Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDecor('Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecor('Years of Experience'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentPositionCtrl,
              decoration: _inputDecor('Current Position'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentCompanyCtrl,
              decoration: _inputDecor('Current Company'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expectedSalaryCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecor('Expected Salary (\$)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: _inputDecor('Notes / Comments').copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                      if (fullNameCtrl.text.trim().isEmpty || nameKhCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Full name and Khmer name are required'),
                          ),
                        );
                        return;
                      }
                      setState(() => _isSubmitting = true);
                      final data = <String, dynamic>{
                        'full_name': fullNameCtrl.text.trim(),
                        'name_kh': nameKhCtrl.text.trim(),
                        if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                        if (phoneCtrl.text.trim().isNotEmpty) 'phone': phoneCtrl.text.trim(),
                        if (expCtrl.text.trim().isNotEmpty)
                          'years_of_experience': int.tryParse(expCtrl.text.trim()),
                        if (currentPositionCtrl.text.trim().isNotEmpty)
                          'current_position': currentPositionCtrl.text.trim(),
                        if (currentCompanyCtrl.text.trim().isNotEmpty)
                          'current_company': currentCompanyCtrl.text.trim(),
                        if (expectedSalaryCtrl.text.trim().isNotEmpty)
                          'expected_salary': double.tryParse(expectedSalaryCtrl.text.trim()),
                        if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                      };
                      try {
                        await RecruitmentRepository().addCandidate(widget.jobId, data);
                        ref.invalidate(jobCandidatesProvider(widget.jobId));
                        ref.invalidate(recruitmentJobsProvider);
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
                  : const Text(
                      'Add Candidate',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
