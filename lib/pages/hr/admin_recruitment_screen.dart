// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart'
    show DepartmentData;
import 'package:mpg_hr_mobile_app/services/hr_repository.dart'
    show PositionData;
import 'package:mpg_hr_mobile_app/services/recruitment_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AdminRecruitmentScreen extends ConsumerWidget {
  const AdminRecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(recruitmentJobsProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.recruitment,
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: jobsAsync.maybeWhen(
        data: (data) => FloatingActionButton(
          onPressed: () =>
              _showJobForm(context, ref, data.departments, data.positions),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        orElse: () => null,
      ),
      body: jobsAsync.when(
        data: (data) {
          final items = data.jobs;
          return items.isEmpty
              ? Center(
                  child: Text(
                    l10n.noJobPostings,
                    style: const TextStyle(color: AppColors.grey400),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final j = items[i];
                    final statusColor = j.status == 'open'
                        ? AppColors.success
                        : j.status == 'closed'
                        ? AppColors.danger
                        : AppColors.warning;
                    return InkWell(
                      onTap: () => _showCandidates(context, j),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.work,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        j.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (j.department != null)
                                        Text(
                                          j.department!.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.grey600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    j.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (j.location != null)
                                  _buildBadge(Icons.location_on, j.location!),
                                if (j.employmentType != null)
                                  _buildBadge(
                                    Icons.access_time,
                                    j.employmentType!.replaceAll('_', ' '),
                                  ),
                                if (j.salaryMin != null)
                                  _buildBadge(
                                    Icons.attach_money,
                                    '\$${j.salaryMin} - \$${j.salaryMax}',
                                  ),
                                _buildBadge(
                                  Icons.people,
                                  '${j.candidatesCount} ${l10n.candidatesTitle}',
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showJobForm(
                                    context,
                                    ref,
                                    data.departments,
                                    data.positions,
                                    job: j,
                                  ),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: Text(l10n.editBtn),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _showCandidates(context, j),
                                  icon: const Icon(Icons.group, size: 16),
                                  label: Text(l10n.candidatesTitle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
        loading: () => LoadingIndicator(message: l10n.loadingJobs),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(recruitmentJobsProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.grey600),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCandidates(BuildContext context, JobPostingData job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _JobCandidatesSheet(job: job),
    );
  }

  void _showJobForm(
    BuildContext context,
    WidgetRef ref,
    List<DepartmentData> depts,
    List<PositionData> pos, {
    JobPostingData? job,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _JobFormSheet(job: job, departments: depts, positions: pos),
    ).then((_) => ref.invalidate(recruitmentJobsProvider));
  }
}

class _JobFormSheet extends StatefulWidget {
  final JobPostingData? job;
  final List<DepartmentData> departments;
  final List<PositionData> positions;
  const _JobFormSheet({
    this.job,
    required this.departments,
    required this.positions,
  });

  @override
  State<_JobFormSheet> createState() => _JobFormSheetState();
}

class _JobFormSheetState extends State<_JobFormSheet> {
  final _repo = RecruitmentRepository();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final reqCtrl = TextEditingController();
  final respCtrl = TextEditingController();
  final locCtrl = TextEditingController();
  final salMinCtrl = TextEditingController();
  final salMaxCtrl = TextEditingController();

  String? selDept;
  String? selPos;
  String selType = 'full_time';
  String selStatus = 'open';
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      titleCtrl.text = widget.job!.title;
      descCtrl.text = widget.job!.description ?? '';
      reqCtrl.text = widget.job!.requirements ?? '';
      respCtrl.text = widget.job!.responsibilities ?? '';
      locCtrl.text = widget.job!.location ?? '';
      salMinCtrl.text = widget.job!.salaryMin?.toString() ?? '';
      salMaxCtrl.text = widget.job!.salaryMax?.toString() ?? '';
      selDept = widget.job!.department?.id.toString();
      selPos = widget.job!.position?.id.toString();
      selType = widget.job!.employmentType ?? 'full_time';
      selStatus = widget.job!.status;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.locationServicesDisabled,
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.locationPermissionDenied,
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.locationPermissionPermDenied,
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty &&
            place.administrativeArea != place.locality) {
          parts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        final formatted = parts.join(', ');

        if (mounted) {
          setState(() {
            locCtrl.text = formatted.isNotEmpty
                ? formatted
                : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📍 ${AppLocalizations.of(context)!.locationUpdated}: ${locCtrl.text}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            locCtrl.text =
                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.couldNotFetchLocation}: $e',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.grey500, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.job != null;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Job Posting' : 'Create Job Posting',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.grey200,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSectionTitle('Basic Information', Icons.info_outline),
                  TextField(
                    controller: titleCtrl,
                    decoration: _inputDecor('Job Title *', Icons.work_outline),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selDept,
                    decoration: _inputDecor('Department', Icons.business),
                    items: widget.departments
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id.toString(),
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selDept = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selPos,
                    decoration: _inputDecor('Position', Icons.badge_outlined),
                    items: widget.positions
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id.toString(),
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selPos = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selType,
                    decoration: _inputDecor(
                      'Employment Type',
                      Icons.access_time,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'full_time',
                        child: Text('Full Time'),
                      ),
                      DropdownMenuItem(
                        value: 'part_time',
                        child: Text('Part Time'),
                      ),
                      DropdownMenuItem(
                        value: 'contract',
                        child: Text('Contract'),
                      ),
                      DropdownMenuItem(
                        value: 'internship',
                        child: Text('Internship'),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => selType = val ?? 'full_time'),
                  ),

                  _buildSectionTitle('Job Details', Icons.description_outlined),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: _inputDecor(
                      'Description *',
                      Icons.text_snippet_outlined,
                    ).copyWith(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reqCtrl,
                    maxLines: 3,
                    decoration: _inputDecor(
                      'Requirements',
                      Icons.fact_check_outlined,
                    ).copyWith(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: respCtrl,
                    maxLines: 3,
                    decoration: _inputDecor(
                      'Responsibilities',
                      Icons.assignment_outlined,
                    ).copyWith(alignLabelWithHint: true),
                  ),

                  _buildSectionTitle('Location & Salary', Icons.place_outlined),
                  TextField(
                    controller: locCtrl,
                    decoration:
                        _inputDecor(
                          'Location',
                          Icons.location_on_outlined,
                        ).copyWith(
                          suffixIcon: _isLocating
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.my_location_rounded,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Get Current Location',
                                  onPressed: _getCurrentLocation,
                                ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: salMinCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecor(
                            'Min Salary',
                            Icons.attach_money,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: salMaxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecor(
                            'Max Salary',
                            Icons.attach_money,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (isEdit) ...[
                    _buildSectionTitle('Status', Icons.flag_outlined),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selStatus,
                      decoration: _inputDecor(
                        'Job Status',
                        Icons.check_circle_outline,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(
                          value: 'closed',
                          child: Text('Closed'),
                        ),
                        DropdownMenuItem(
                          value: 'filled',
                          child: Text('Filled'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => selStatus = val ?? 'open'),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Title and description required'),
                            ),
                          );
                          return;
                        }
                        final data = {
                          'title': titleCtrl.text,
                          'description': descCtrl.text,
                          'requirements': reqCtrl.text,
                          'responsibilities': respCtrl.text,
                          'employment_type': selType,
                          'location': locCtrl.text,
                          if (salMinCtrl.text.isNotEmpty)
                            'salary_min': double.tryParse(salMinCtrl.text),
                          if (salMaxCtrl.text.isNotEmpty)
                            'salary_max': double.tryParse(salMaxCtrl.text),
                          if (selDept != null) 'department_id': selDept,
                          if (selPos != null) 'position_id': selPos,
                          'status': selStatus,
                        };
                        try {
                          if (isEdit) {
                            await _repo.updateJob(widget.job!.id, data);
                          } else {
                            await _repo.createJob(data);
                          }
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(
                        isEdit ? 'Update Job Posting' : 'Publish Job Posting',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCandidatesSheet extends ConsumerWidget {
  final JobPostingData job;
  const _JobCandidatesSheet({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(jobCandidatesProvider(job.id));
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Candidates: ${job.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: candidatesAsync.when(
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text(
                        'No candidates applied yet.',
                        style: TextStyle(color: AppColors.grey500),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final c = items[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.primaryLight,
                                            Colors.white,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: AppColors.grey800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (c.email != null)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.email_outlined,
                                                  size: 14,
                                                  color: AppColors.grey500,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    c.email!,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors.grey700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 2),
                                          if (c.phone != null)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.phone_outlined,
                                                  size: 14,
                                                  color: AppColors.grey500,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    c.phone!,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors.grey700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (c.yearsOfExperience != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundLight,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.grey200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.work_history_outlined,
                                              size: 14,
                                              color: AppColors.grey600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${c.yearsOfExperience} yrs exp',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.grey700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (c.expectedSalary != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF9C3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFEF08A),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.attach_money,
                                              size: 14,
                                              color: Color(0xFFCA8A04),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Exp \$${c.expectedSalary}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFCA8A04),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (c.resume != null) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.description_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'View Resume',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      minimumSize: const Size(
                                        double.infinity,
                                        44,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                                if (c.stage == 'hired') ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await RecruitmentRepository().convertToEmployee(c.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Candidate successfully converted to Employee.'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('❌ $e'),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.person_add_outlined, size: 18),
                                    label: const Text('Convert to Employee', style: TextStyle(fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade50,
                                      foregroundColor: Colors.purple.shade700,
                                      elevation: 0,
                                      minimumSize: const Size(double.infinity, 44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.grey200,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.track_changes_outlined,
                                      size: 18,
                                      color: AppColors.grey500,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Stage',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.grey700,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue:
                                            [
                                              'applied',
                                              'screening',
                                              'interview',
                                              'offer',
                                              'hired',
                                              'rejected',
                                            ].contains(c.stage)
                                            ? c.stage
                                            : 'applied',
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppColors.grey500,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.grey300,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.grey300,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: AppColors.backgroundLight,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey800,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'applied',
                                            child: Text('Applied'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'screening',
                                            child: Text('Screening'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'interview',
                                            child: Text('Interview'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'offer',
                                            child: Text('Offer'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'hired',
                                            child: Text('Hired'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'rejected',
                                            child: Text('Rejected'),
                                          ),
                                        ],
                                        onChanged: (val) async {
                                          if (val != null && val != c.stage) {
                                            try {
                                              await RecruitmentRepository()
                                                  .updateCandidateStatus(
                                                    c.id,
                                                    val,
                                                  );
                                              ref.invalidate(
                                                jobCandidatesProvider(job.id),
                                              );
                                              ref.invalidate(
                                                recruitmentJobsProvider,
                                              );
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('❌ $e'),
                                                    backgroundColor:
                                                        AppColors.danger,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              loading: () =>
                  const LoadingIndicator(message: 'Loading candidates...'),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
