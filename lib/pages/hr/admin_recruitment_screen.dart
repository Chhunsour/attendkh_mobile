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

class AdminRecruitmentScreen extends ConsumerStatefulWidget {
  const AdminRecruitmentScreen({super.key});

  @override
  ConsumerState<AdminRecruitmentScreen> createState() =>
      _AdminRecruitmentScreenState();
}

class _AdminRecruitmentScreenState
    extends ConsumerState<AdminRecruitmentScreen> {
  String _search = '';
  String _statusFilter = '';
  String _typeFilter = '';

  List<JobPostingData> _applyFilters(List<JobPostingData> jobs) {
    var filtered = jobs;
    if (_search.isNotEmpty) {
      filtered = filtered
          .where((j) => j.title.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    if (_statusFilter.isNotEmpty) {
      filtered = filtered.where((j) => j.status == _statusFilter).toList();
    }
    if (_typeFilter.isNotEmpty) {
      filtered = filtered
          .where((j) => j.employmentType == _typeFilter)
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.grey900,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      floatingActionButton: jobsAsync.maybeWhen(
        data: (data) => GestureDetector(
          onTap: () =>
              _showJobForm(context, ref, data.departments, data.positions),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(70),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Post New Job',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        orElse: () => null,
      ),
      body: jobsAsync.when(
        data: (data) {
          final items = _applyFilters(data.jobs);
          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.grey50,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.work_outline,
                                size: 32,
                                color: AppColors.grey300,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noJobPostings,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting your search or filters.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final j = items[i];
                          return _buildJobCard(j, data, l10n);
                        },
                      ),
              ),
            ],
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

  Widget _buildJobCard(JobPostingData j, dynamic data, dynamic l10n) {
    final statusStyles = _getStatusStyles(j.status);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200.withAlpha(128)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCandidates(context, j),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title + Status badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          j.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.grey900,
                          ),
                        ),
                        if (j.employmentType != null)
                          Text(
                            j.employmentType!.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyles['bg'],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusStyles['border']!),
                    ),
                    child: Text(
                      j.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusStyles['text'],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Row 2: Info badges (location, salary, vacancies, closing date)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (j.location != null)
                    _buildInfoBadge(
                      Icons.location_on,
                      j.location!,
                      AppColors.success,
                      AppColors.successLight,
                    ),
                  if (j.salaryMin != null)
                    _buildInfoBadge(
                      Icons.attach_money,
                      '\$${j.salaryMin?.toStringAsFixed(0)} - \$${j.salaryMax?.toStringAsFixed(0)}',
                      AppColors.success,
                      AppColors.successLight,
                    ),
                  _buildInfoBadge(
                    Icons.people_outline,
                    '${j.positionsAvailable} Vacancies',
                    AppColors.primary,
                    AppColors.primaryLight,
                  ),
                  _buildInfoBadge(
                    Icons.event_outlined,
                    j.closingDate != null && j.closingDate!.isNotEmpty
                        ? j.closingDate!.split('T')[0]
                        : 'Ongoing',
                    AppColors.grey600,
                    AppColors.grey100,
                  ),
                  _buildInfoBadge(
                    Icons.group,
                    '${j.candidatesCount} Candidates',
                    AppColors.grey700,
                    AppColors.grey100,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Row 3: Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    color: AppColors.grey500,
                    onTap: () => _showCandidates(context, j),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    label: l10n.editBtn,
                    color: AppColors.primary,
                    onTap: () => _showJobForm(
                      context,
                      ref,
                      data.departments,
                      data.positions,
                      job: j,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.danger,
                    onTap: () => _confirmDelete(context, ref, j),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getStatusStyles(String status) {
    switch (status) {
      case 'open':
        return {
          'bg': const Color(0xFFECFDF5),
          'text': const Color(0xFF059669),
          'border': const Color(0xFFA7F3D0),
        };
      case 'closed':
        return {
          'bg': const Color(0xFFFFF1F2),
          'text': const Color(0xFFE11D48),
          'border': const Color(0xFFFECDD3),
        };
      case 'filled':
        return {
          'bg': AppColors.primaryLight,
          'text': AppColors.primary,
          'border': AppColors.primaryLight,
        };
      default: // draft
        return {
          'bg': AppColors.grey50,
          'text': AppColors.grey700,
          'border': AppColors.grey200,
        };
    }
  }

  Widget _buildInfoBadge(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200.withAlpha(128)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextFormField(
            initialValue: _search,
            onChanged: (val) => setState(() => _search = val),
            decoration: InputDecoration(
              hintText: 'Search job titles...',
              hintStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.grey400,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.grey50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          // Filter dropdowns
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _statusFilter.isEmpty ? null : _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'All Statuses',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'draft',
                      child: Text('Draft', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'open',
                      child: Text('Open', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'closed',
                      child: Text('Closed', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'filled',
                      child: Text('Filled', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (val) => setState(() => _statusFilter = val ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _typeFilter.isEmpty ? null : _typeFilter,
                  decoration: InputDecoration(
                    labelText: 'All Types',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'full_time',
                      child: Text('Full Time', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'part_time',
                      child: Text('Part Time', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'contract',
                      child: Text('Contract', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'internship',
                      child: Text('Internship', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (val) => setState(() => _typeFilter = val ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, JobPostingData job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job Posting'),
        content: Text(
          'Are you sure you want to delete "${job.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await RecruitmentRepository().deleteJob(job.id);
                ref.invalidate(recruitmentJobsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
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
  final mapUrlCtrl = TextEditingController();
  final salMinCtrl = TextEditingController();
  final salMaxCtrl = TextEditingController();
  final positionsCtrl = TextEditingController(text: '1');
  final closingDateCtrl = TextEditingController();
  final expLevelCtrl = TextEditingController();
  final eduLevelCtrl = TextEditingController();
  final skillsCtrl = TextEditingController();
  final ageReqCtrl = TextEditingController();
  final howToApplyCtrl = TextEditingController();
  final contactInfoCtrl = TextEditingController();
  final benefitsCtrl = TextEditingController();

  String? selDept;
  String? selPos;
  String selType = 'full_time';
  String selStatus = 'open';
  String selGender = '';
  bool _isLocating = false;
  int _activeTab = 0; // 0=basic, 1=criteria, 2=details

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      titleCtrl.text = widget.job!.title;
      descCtrl.text = widget.job!.description ?? '';
      reqCtrl.text = widget.job!.requirements ?? '';
      respCtrl.text = widget.job!.responsibilities ?? '';
      locCtrl.text = widget.job!.location ?? '';
      mapUrlCtrl.text = widget.job!.mapUrl ?? '';
      salMinCtrl.text = widget.job!.salaryMin?.toString() ?? '';
      salMaxCtrl.text = widget.job!.salaryMax?.toString() ?? '';
      positionsCtrl.text = widget.job!.positionsAvailable.toString();
      closingDateCtrl.text = widget.job!.closingDate ?? '';
      expLevelCtrl.text = widget.job!.experienceLevel ?? '';
      eduLevelCtrl.text = widget.job!.educationLevel ?? '';
      skillsCtrl.text = widget.job!.skills ?? '';
      ageReqCtrl.text = widget.job!.ageRequirement ?? '';
      howToApplyCtrl.text = widget.job!.howToApply ?? '';
      contactInfoCtrl.text = widget.job!.contactInfo ?? '';
      benefitsCtrl.text = widget.job!.benefits ?? '';
      selDept = widget.job!.department?.id.toString();
      selPos = widget.job!.position?.id.toString();
      selType = widget.job!.employmentType ?? 'full_time';
      selStatus = widget.job!.status;
      selGender = widget.job!.genderPreference ?? '';
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
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.grey700,
      ),
      prefixIcon: Icon(icon, color: AppColors.grey400, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.grey50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(40),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : AppColors.grey500,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${index + 1}. $label',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.grey500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit
                      ? 'Edit Job Posting'
                      : 'New Job Posting (18 Recruitment Fields)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.grey100,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: 8),
            // Tab bar
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.grey200)),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'Basic Info', Icons.work_outline),
                  _buildTabButton(
                    1,
                    'Criteria',
                    Icons.workspace_premium_outlined,
                  ),
                  _buildTabButton(2, 'Details', Icons.description_outlined),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // TAB 0: BASIC INFORMATION
                  if (_activeTab == 0) ...[
                    _buildSectionTitle('Basic Information', Icons.info_outline),
                    TextField(
                      controller: titleCtrl,
                      decoration: _inputDecor(
                        'Job Title *',
                        Icons.work_outline,
                      ),
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
                    const SizedBox(height: 16),
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
                    TextField(
                      controller: mapUrlCtrl,
                      maxLines: 2,
                      decoration: _inputDecor(
                        'Google Maps Embed URL (optional)',
                        Icons.map_outlined,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    if (isEdit)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selStatus,
                        decoration: _inputDecor(
                          'Status',
                          Icons.check_circle_outline,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: salMinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecor(
                              'Min Salary (\$)',
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
                              'Max Salary (\$)',
                              Icons.attach_money,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: positionsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecor(
                              'Vacancies',
                              Icons.people_outline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: closingDateCtrl,
                            readOnly: true,
                            decoration:
                                _inputDecor(
                                  'Closing Date',
                                  Icons.event_outlined,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: AppColors.grey500,
                                    ),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (date != null) {
                                        closingDateCtrl.text = date
                                            .toIso8601String()
                                            .split('T')[0];
                                      }
                                    },
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // TAB 1: QUALIFICATIONS & CRITERIA
                  if (_activeTab == 1) ...[
                    _buildSectionTitle(
                      'Qualifications & Criteria',
                      Icons.workspace_premium_outlined,
                    ),
                    TextField(
                      controller: expLevelCtrl,
                      decoration: _inputDecor(
                        'Experience Level',
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: eduLevelCtrl,
                      decoration: _inputDecor(
                        'Education Level',
                        Icons.school_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: skillsCtrl,
                      decoration: _inputDecor(
                        'Required Skills (comma-separated)',
                        Icons.build_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selGender.isEmpty ? null : selGender,
                      decoration: _inputDecor(
                        'Gender Preference',
                        Icons.wc_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Any Gender')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'Male / Female',
                          child: Text('Male / Female'),
                        ),
                      ],
                      onChanged: (val) => setState(() => selGender = val ?? ''),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ageReqCtrl,
                      decoration: _inputDecor(
                        'Age Requirement',
                        Icons.cake_outlined,
                      ),
                    ),
                  ],

                  // TAB 2: RICH CONTENT & INSTRUCTIONS
                  if (_activeTab == 2) ...[
                    _buildSectionTitle(
                      'Rich Content & Instructions',
                      Icons.description_outlined,
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: _inputDecor(
                        'Job Description *',
                        Icons.text_snippet_outlined,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: respCtrl,
                      maxLines: 4,
                      decoration: _inputDecor(
                        'Responsibilities',
                        Icons.assignment_outlined,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reqCtrl,
                      maxLines: 4,
                      decoration: _inputDecor(
                        'Requirements',
                        Icons.fact_check_outlined,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: benefitsCtrl,
                      maxLines: 3,
                      decoration: _inputDecor(
                        'Benefits & Perks',
                        Icons.card_giftcard_outlined,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: howToApplyCtrl,
                      maxLines: 3,
                      decoration: _inputDecor(
                        'How to Apply',
                        Icons.send_outlined,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contactInfoCtrl,
                      maxLines: 3,
                      decoration: _inputDecor(
                        'Contact Information',
                        Icons.contact_phone_outlined,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                  ],

                  // Navigation + Submit buttons
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.grey200),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous / Cancel
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _activeTab > 0
                              ? OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.grey600,
                                    side: BorderSide(color: AppColors.grey200),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: () => setState(() => _activeTab--),
                                  child: const Text(
                                    'Previous',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.grey600,
                                    side: BorderSide(color: AppColors.grey200),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Next / Submit
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _activeTab < 2
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.grey900,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: () => setState(() => _activeTab++),
                                  child: const Text(
                                    'Next Step →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: AppColors.primary.withAlpha(
                                      60,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (titleCtrl.text.isEmpty ||
                                        descCtrl.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Title and description required',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final data = <String, dynamic>{
                                      'title': titleCtrl.text,
                                      'description': descCtrl.text,
                                      'requirements': reqCtrl.text,
                                      'responsibilities': respCtrl.text,
                                      'employment_type': selType,
                                      'location': locCtrl.text,
                                      if (mapUrlCtrl.text.isNotEmpty)
                                        'map_url': mapUrlCtrl.text,
                                      if (salMinCtrl.text.isNotEmpty)
                                        'salary_min': double.tryParse(
                                          salMinCtrl.text,
                                        ),
                                      if (salMaxCtrl.text.isNotEmpty)
                                        'salary_max': double.tryParse(
                                          salMaxCtrl.text,
                                        ),
                                      'positions_available':
                                          int.tryParse(positionsCtrl.text) ?? 1,
                                      if (closingDateCtrl.text.isNotEmpty)
                                        'closing_date': closingDateCtrl.text,
                                      if (selDept != null)
                                        'department_id': selDept,
                                      if (selPos != null) 'position_id': selPos,
                                      'status': selStatus,
                                      if (expLevelCtrl.text.isNotEmpty)
                                        'experience_level': expLevelCtrl.text,
                                      if (eduLevelCtrl.text.isNotEmpty)
                                        'education_level': eduLevelCtrl.text,
                                      if (skillsCtrl.text.isNotEmpty)
                                        'skills': skillsCtrl.text,
                                      if (selGender.isNotEmpty)
                                        'gender_preference': selGender,
                                      if (ageReqCtrl.text.isNotEmpty)
                                        'age_requirement': ageReqCtrl.text,
                                      if (howToApplyCtrl.text.isNotEmpty)
                                        'how_to_apply': howToApplyCtrl.text,
                                      if (contactInfoCtrl.text.isNotEmpty)
                                        'contact_info': contactInfoCtrl.text,
                                      if (benefitsCtrl.text.isNotEmpty)
                                        'benefits': benefitsCtrl.text,
                                    };
                                    try {
                                      if (isEdit) {
                                        await _repo.updateJob(
                                          widget.job!.id,
                                          data,
                                        );
                                      } else {
                                        await _repo.createJob(data);
                                      }
                                      if (mounted) Navigator.pop(context);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    isEdit ? 'Update Job' : 'Publish Job',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
      ),
    );
  }
}

class _JobCandidatesSheet extends ConsumerWidget {
  final JobPostingData job;
  const _JobCandidatesSheet({required this.job});

  void _showAddCandidateForm(BuildContext context, WidgetRef ref) {
    final fullNameCtrl = TextEditingController();
    final nameKhCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final currentPositionCtrl = TextEditingController();
    final currentCompanyCtrl = TextEditingController();
    final expectedSalaryCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Candidate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey800,
                ),
              ),
              const Divider(height: 24, color: AppColors.grey200),
              TextField(
                controller: fullNameCtrl,
                decoration: _candidateInputDecor('Full Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameKhCtrl,
                decoration: _candidateInputDecor('Name (Khmer) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _candidateInputDecor('Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _candidateInputDecor('Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expCtrl,
                keyboardType: TextInputType.number,
                decoration: _candidateInputDecor('Years of Experience'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentPositionCtrl,
                decoration: _candidateInputDecor('Current Position'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentCompanyCtrl,
                decoration: _candidateInputDecor('Current Company'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expectedSalaryCtrl,
                keyboardType: TextInputType.number,
                decoration: _candidateInputDecor('Expected Salary'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: _candidateInputDecor(
                  'Notes',
                ).copyWith(alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withAlpha(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  if (fullNameCtrl.text.isEmpty || nameKhCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Full name and Khmer name required'),
                      ),
                    );
                    return;
                  }
                  final data = <String, dynamic>{
                    'full_name': fullNameCtrl.text,
                    'name_kh': nameKhCtrl.text,
                    if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text,
                    if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text,
                    if (expCtrl.text.isNotEmpty)
                      'years_of_experience': int.tryParse(expCtrl.text),
                    if (currentPositionCtrl.text.isNotEmpty)
                      'current_position': currentPositionCtrl.text,
                    if (currentCompanyCtrl.text.isNotEmpty)
                      'current_company': currentCompanyCtrl.text,
                    if (expectedSalaryCtrl.text.isNotEmpty)
                      'expected_salary': double.tryParse(
                        expectedSalaryCtrl.text,
                      ),
                    if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text,
                  };
                  try {
                    await RecruitmentRepository().addCandidate(job.id, data);
                    ref.invalidate(jobCandidatesProvider(job.id));
                    ref.invalidate(recruitmentJobsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text(
                  'Add Candidate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _candidateInputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.grey700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.grey50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }

  void _showScheduleInterviewForm(
    BuildContext context,
    WidgetRef ref,
    int candidateId,
  ) {
    String selType = 'phone';
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');
    final locationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Schedule Interview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                  ),
                ),
                const Divider(height: 24, color: AppColors.grey200),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selType,
                  decoration: InputDecoration(
                    labelText: 'Interview Type',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'phone',
                      child: Text('Phone', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'video',
                      child: Text('Video', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'in_person',
                      child: Text('In Person', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'technical',
                      child: Text('Technical', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (val) =>
                      setModalState(() => selType = val ?? 'phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date *',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.grey400,
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
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
                  decoration: InputDecoration(
                    labelText: 'Time *',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.grey400,
                      ),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: ctx,
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
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Location / Link',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.primary.withAlpha(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (dateCtrl.text.isEmpty || timeCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Date and time required')),
                      );
                      return;
                    }
                    final data = <String, dynamic>{
                      'type': selType,
                      'scheduled_at': '${dateCtrl.text} ${timeCtrl.text}',
                      'duration_minutes': int.tryParse(durationCtrl.text) ?? 30,
                      if (locationCtrl.text.isNotEmpty)
                        'location': locationCtrl.text,
                    };
                    try {
                      await RecruitmentRepository().scheduleInterview(
                        candidateId,
                        data,
                      );
                      ref.invalidate(jobCandidatesProvider(job.id));
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(
                          ctx,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text(
                    'Schedule Interview',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(jobCandidatesProvider(job.id));
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header matching web
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Candidates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.grey100,
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Add Candidate button matching web style
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCandidateForm(context, ref),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text(
                'Add Candidate',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 1,
                shadowColor: AppColors.primary.withAlpha(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: candidatesAsync.when(
              data: (items) => items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 32,
                              color: AppColors.grey300,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No candidates found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add candidates to this job posting',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final c = items[i];
                        return _buildCandidateCard(ctx, ref, c);
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

  Widget _buildCandidateCard(
    BuildContext context,
    WidgetRef ref,
    CandidateData c,
  ) {
    final statusStyles = _getCandidateStatusStyles(c.stage);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200.withAlpha(128)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Status badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.fullName ?? c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.grey900,
                        ),
                      ),
                      if (c.nameKh != null && c.nameKh!.isNotEmpty)
                        Text(
                          c.nameKh!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                      if (c.currentPosition != null)
                        Text(
                          c.currentPosition!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusStyles['bg'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusStyles['border']!),
                  ),
                  child: Text(
                    c.stage.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusStyles['text'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Contact info
            if (c.email != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.email!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (c.phone != null)
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // Info badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (c.yearsOfExperience != null)
                  _buildInfoBadge(
                    Icons.work_history_outlined,
                    '${c.yearsOfExperience} yrs',
                    AppColors.grey600,
                    AppColors.grey100,
                  ),
                if (c.expectedSalary != null)
                  _buildInfoBadge(
                    Icons.attach_money,
                    'Exp \$${c.expectedSalary?.toStringAsFixed(0)}',
                    const Color(0xFFCA8A04),
                    const Color(0xFFFEF9C3),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (c.resume != null)
                  _buildActionButton(
                    icon: Icons.description_outlined,
                    label: 'Resume',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                _buildActionButton(
                  icon: Icons.event_outlined,
                  label: 'Interview',
                  color: const Color(0xFF16A34A),
                  onTap: () => _showScheduleInterviewForm(context, ref, c.id),
                ),
                if (c.stage == 'hired')
                  _buildActionButton(
                    icon: Icons.person_add_outlined,
                    label: 'Convert',
                    color: Colors.purple,
                    onTap: () async {
                      try {
                        await RecruitmentRepository().convertToEmployee(c.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Candidate successfully converted to Employee.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: 12),
            // Status dropdown
            Row(
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: DropdownButton<String>(
                      value:
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
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.grey400,
                        size: 18,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey700,
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
                        DropdownMenuItem(value: 'offer', child: Text('Offer')),
                        DropdownMenuItem(value: 'hired', child: Text('Hired')),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Rejected'),
                        ),
                      ],
                      onChanged: (val) async {
                        if (val != null && val != c.stage) {
                          try {
                            await RecruitmentRepository().updateCandidateStatus(
                              c.id,
                              val,
                            );
                            ref.invalidate(jobCandidatesProvider(job.id));
                            ref.invalidate(recruitmentJobsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getCandidateStatusStyles(String status) {
    switch (status) {
      case 'hired':
        return {
          'bg': const Color(0xFFECFDF5),
          'text': const Color(0xFF059669),
          'border': const Color(0xFFA7F3D0),
        };
      case 'interview':
        return {
          'bg': const Color(0xFFEFF6FF),
          'text': const Color(0xFF2563EB),
          'border': const Color(0xFFBFDBFE),
        };
      case 'offer':
        return {
          'bg': const Color(0xFFF5F3FF),
          'text': const Color(0xFF7C3AED),
          'border': const Color(0xFFDDD6FE),
        };
      case 'rejected':
        return {
          'bg': const Color(0xFFFFF1F2),
          'text': const Color(0xFFE11D48),
          'border': const Color(0xFFFECDD3),
        };
      case 'screening':
        return {
          'bg': const Color(0xFFFFFBEB),
          'text': const Color(0xFFD97706),
          'border': const Color(0xFFFDE68A),
        };
      default: // applied
        return {
          'bg': AppColors.grey50,
          'text': AppColors.grey700,
          'border': AppColors.grey200,
        };
    }
  }

  Widget _buildInfoBadge(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
