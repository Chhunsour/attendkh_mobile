// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/services/documents_repository.dart' show DepartmentData;
import 'package:attendkh/services/hr_repository.dart' show PositionData;
import 'package:attendkh/services/recruitment_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';

class JobFormSheet extends StatefulWidget {
  final JobPostingData? job;
  final List<DepartmentData> departments;
  final List<PositionData> positions;

  const JobFormSheet({
    super.key,
    this.job,
    required this.departments,
    required this.positions,
  });

  @override
  State<JobFormSheet> createState() => _JobFormSheetState();
}

class _JobFormSheetState extends State<JobFormSheet> {
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

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    reqCtrl.dispose();
    respCtrl.dispose();
    locCtrl.dispose();
    mapUrlCtrl.dispose();
    salMinCtrl.dispose();
    salMaxCtrl.dispose();
    positionsCtrl.dispose();
    closingDateCtrl.dispose();
    expLevelCtrl.dispose();
    eduLevelCtrl.dispose();
    skillsCtrl.dispose();
    ageReqCtrl.dispose();
    howToApplyCtrl.dispose();
    contactInfoCtrl.dispose();
    benefitsCtrl.dispose();
    super.dispose();
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
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
        color: AppColors.grey600,
      ),
      prefixIcon: Icon(icon, color: AppColors.grey400, size: 18),
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
                    fontSize: 10.5,
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
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.job != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      : 'New Job Posting',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
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
                      items: [
                        DropdownMenuItem(
                          value: 'full_time',
                          child: Text(l10n.fullTime),
                        ),
                        DropdownMenuItem(
                          value: 'part_time',
                          child: Text(l10n.partTime),
                        ),
                        DropdownMenuItem(
                          value: 'contract',
                          child: Text(l10n.contract),
                        ),
                        DropdownMenuItem(
                          value: 'internship',
                          child: Text(l10n.internship),
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
                        items: [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text(l10n.draft),
                          ),
                          const DropdownMenuItem(value: 'open', child: Text('Open')),
                          const DropdownMenuItem(
                            value: 'closed',
                            child: Text('Closed'),
                          ),
                          const DropdownMenuItem(
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
                                    side: const BorderSide(color: AppColors.grey200),
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
                                    side: const BorderSide(color: AppColors.grey200),
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
                                  child: Text(
                                    l10n.nextStep,
                                    style: const TextStyle(
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
                                    shadowColor: AppColors.primary.withAlpha(60),
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
                                      ScaffoldMessenger.of(context).showSnackBar(
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
                                        ScaffoldMessenger.of(context).showSnackBar(
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