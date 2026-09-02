// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

enum HolidayViewMode { calendar, list }

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  State<AdminHolidaysScreen> createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends State<AdminHolidaysScreen> {
  bool _loading = true;
  List<HolidayData> _items = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  HolidayViewMode _viewMode = HolidayViewMode.calendar;
  String _selectedFilter = 'all'; // 'all', 'national', 'company', 'upcoming'
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await AdminOperationsRepository().getHolidays();
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<HolidayData> _getHolidaysForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _items.where((h) {
      final hDate = DateTime.tryParse(h.date);
      if (hDate == null) return false;
      if (h.isRecurring) {
        return hDate.month == day.month && hDate.day == day.day;
      }
      return h.date == dateStr;
    }).toList();
  }

  HolidayData? _getNextUpcomingHoliday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    HolidayData? next;
    DateTime? nextDate;

    for (final h in _items) {
      final parsed = DateTime.tryParse(h.date);
      if (parsed == null) continue;
      final targetDate = h.isRecurring
          ? DateTime(today.year, parsed.month, parsed.day)
          : parsed;

      if (!targetDate.isBefore(today)) {
        if (nextDate == null || targetDate.isBefore(nextDate)) {
          nextDate = targetDate;
          next = h;
        }
      }
    }
    return next;
  }

  int _daysUntil(HolidayData holiday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parsed = DateTime.tryParse(holiday.date);
    if (parsed == null) return 0;
    final targetDate = holiday.isRecurring
        ? DateTime(today.year, parsed.month, parsed.day)
        : parsed;
    return targetDate.difference(today).inDays;
  }

  List<HolidayData> get _filteredHolidays {
    var list = _items.where((h) {
      final parsed = DateTime.tryParse(h.date);
      if (parsed == null) return false;
      if (h.isRecurring) return true;
      return parsed.year == _selectedYear;
    }).toList();

    if (_selectedFilter == 'national') {
      list = list.where((h) => h.type == 'national').toList();
    } else if (_selectedFilter == 'company') {
      list = list.where((h) => h.type == 'company').toList();
    } else if (_selectedFilter == 'upcoming') {
      final today = DateTime.now();
      list = list.where((h) {
        final parsed = DateTime.tryParse(h.date);
        if (parsed == null) return false;
        final targetDate = h.isRecurring
            ? DateTime(today.year, parsed.month, parsed.day)
            : parsed;
        return !targetDate.isBefore(DateTime(today.year, today.month, today.day));
      }).toList();
    }

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  void _showYearPicker() {
    HapticFeedback.mediumImpact();
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (i) => currentYear - 5 + i);
    final scrollController = ScrollController(
      initialScrollOffset: (years.indexOf(_selectedYear)).clamp(0, years.length - 1) * 56.0,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select Year',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(ctx),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: years.length,
                  itemBuilder: (ctx, i) {
                    final year = years[i];
                    final isSelected = year == _selectedYear;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedYear = year;
                          _focusedDay = DateTime(year, _focusedDay.month, 1);
                        });
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$year',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFFD97706)
                                    : AppColors.textPrimary(ctx),
                              ),
                            ),
                            if (year == currentYear)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            if (isSelected && year != currentYear)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showForm([HolidayData? item, DateTime? selectedDate]) {
    HapticFeedback.mediumImpact();
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: isEdit ? item.name : '');
    final dateCtrl = TextEditingController(
      text: isEdit
          ? item.date
          : (selectedDate != null
              ? DateFormat('yyyy-MM-dd').format(selectedDate)
              : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)))),
    );
    final descCtrl = TextEditingController(text: isEdit ? (item.description ?? '') : '');
    String selectedType = isEdit ? item.type : 'company';
    bool isRecurring = isEdit ? item.isRecurring : false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final l10n = AppLocalizations.of(ctx)!;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle pill
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? l10n.editHoliday : l10n.addHoliday,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(ctx),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (selectedType == 'national' ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            selectedType == 'national' ? '🇰🇭 National' : '🏢 Company',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selectedType == 'national' ? const Color(0xFF8B5CF6) : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Type Selector Pills
                    Text(
                      l10n.holidayTypeLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(ctx),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedType = 'company'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == 'company'
                                    ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedType == 'company'
                                      ? const Color(0xFFF59E0B)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    size: 18,
                                    color: selectedType == 'company'
                                        ? const Color(0xFFD97706)
                                        : AppColors.textSecondary(ctx),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.holidayTypeCompany,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: selectedType == 'company'
                                          ? const Color(0xFFD97706)
                                          : AppColors.textSecondary(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedType = 'national'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == 'national'
                                    ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedType == 'national'
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 18,
                                    color: selectedType == 'national'
                                        ? const Color(0xFF8B5CF6)
                                        : AppColors.textSecondary(ctx),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.holidayTypeNational,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: selectedType == 'national'
                                          ? const Color(0xFF8B5CF6)
                                          : AppColors.textSecondary(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Holiday Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.holidayNameLabel,
                        hintText: 'e.g. Khmer New Year Day 1',
                        prefixIcon: const Icon(Icons.celebration_outlined, size: 20),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border(ctx)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border(ctx)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date Picker Input
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: l10n.holidayDateLabel,
                        prefixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border(ctx)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border(ctx)),
                        ),
                      ),
                      onTap: () async {
                        final defaultDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));
                        final initDate = DateTime.tryParse(dateCtrl.text) ?? defaultDate;
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: initDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.holidayDescriptionLabel,
                        hintText: 'Optional details...',
                        prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border(ctx)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border(ctx)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Annual Recurring Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(ctx)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.repeat_rounded, size: 20, color: Color(0xFF10B981)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Repeats Annually',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary(ctx),
                                    ),
                                  ),
                                  Text(
                                    'Auto-applies to future years',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: isRecurring,
                            activeTrackColor: const Color(0xFF10B981),
                            onChanged: (val) => setSheetState(() => isRecurring = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        if (isEdit) ...[
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmDelete(item.id, item.name);
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (nameCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.pleaseFillRequired)),
                                      );
                                      return;
                                    }

                                    setSheetState(() => isSaving = true);
                                    try {
                                      if (isEdit) {
                                        await AdminOperationsRepository().updateHoliday(item.id, {
                                          'name': nameCtrl.text.trim(),
                                          'date': dateCtrl.text.trim(),
                                          'type': selectedType,
                                          'description': descCtrl.text.trim(),
                                          'is_recurring': isRecurring,
                                        });
                                      } else {
                                        await AdminOperationsRepository().createHoliday(
                                          name: nameCtrl.text.trim(),
                                          date: dateCtrl.text.trim(),
                                          type: selectedType,
                                          description: descCtrl.text.trim(),
                                          isRecurring: isRecurring,
                                        );
                                      }

                                      if (mounted) {
                                        Navigator.pop(ctx);
                                        _fetchData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(l10n.holidayCreatedSuccess),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => isSaving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                                        );
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    isEdit ? 'Update' : l10n.save,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.deleteHolidayTitle,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.deleteHolidayConfirm(name),
            style: const TextStyle(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  await AdminOperationsRepository().deleteHoliday(id);
                  _fetchData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.holidayDeletedSuccess),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final nextHoliday = _getNextUpcomingHoliday();
    final holidaysInSelectedYear = _items.where((h) {
      final parsed = DateTime.tryParse(h.date);
      if (parsed == null) return false;
      return h.isRecurring || parsed.year == _selectedYear;
    }).toList();

    final nationalCount = holidaysInSelectedYear.where((h) => h.type == 'national').length;
    final companyCount = holidaysInSelectedYear.where((h) => h.type == 'company').length;
    final selectedDayHolidays = _selectedDay != null ? _getHolidaysForDay(_selectedDay!) : <HolidayData>[];

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.holidaysTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Holiday',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 20),
            ),
            onPressed: () => _showForm(null, _selectedDay),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? LoadingIndicator(message: l10n.loadingHolidays)
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  // ── 1. Executive Amber/Orange Holiday Banner ───────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEA580C),
                          Color(0xFFF59E0B),
                          Color(0xFFD97706),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.celebration_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_selectedYear Holiday Calendar',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.officialDaysOff,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Year Picker Chip
                            GestureDetector(
                              onTap: _showYearPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$_selectedYear',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.expand_more_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats Summary Row
                        Row(
                          children: [
                            _buildStatPill(
                              label: l10n.totalOff,
                              value: '${holidaysInSelectedYear.length} Days',
                              icon: Icons.calendar_today_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildStatPill(
                              label: 'National',
                              value: '$nationalCount',
                              icon: Icons.flag_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildStatPill(
                              label: 'Company',
                              value: '$companyCount',
                              icon: Icons.business_rounded,
                            ),
                          ],
                        ),

                        // Next Holiday Countdown Pill
                        if (nextHoliday != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      children: [
                                        const TextSpan(text: 'Next Holiday: '),
                                        TextSpan(
                                          text: nextHoliday.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: ' (${_daysUntil(nextHoliday) == 0 ? 'Today 🎉' : 'in ${_daysUntil(nextHoliday)} days'})',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── 2. View Switcher Tabs (Calendar vs List) ───────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _viewMode = HolidayViewMode.calendar);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _viewMode == HolidayViewMode.calendar
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 16,
                                    color: _viewMode == HolidayViewMode.calendar
                                        ? Colors.white
                                        : AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Calendar View',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _viewMode == HolidayViewMode.calendar
                                          ? Colors.white
                                          : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _viewMode = HolidayViewMode.list);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _viewMode == HolidayViewMode.list
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.format_list_bulleted_rounded,
                                    size: 16,
                                    color: _viewMode == HolidayViewMode.list
                                        ? Colors.white
                                        : AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.yearListView,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _viewMode == HolidayViewMode.list
                                          ? Colors.white
                                          : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 3. Filter Chips ───────────────────────────────────────
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip('all', 'All (${holidaysInSelectedYear.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('national', '🇰🇭 National ($nationalCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('company', '🏢 Company ($companyCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('upcoming', '⏳ Upcoming'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 4. Main Body: Calendar or List View ───────────────────
                  if (_viewMode == HolidayViewMode.calendar) ...[
                    _buildCalendarCard(context, isDark),
                    const SizedBox(height: 14),
                    _buildSelectedDaySection(context, isDark, selectedDayHolidays),
                  ] else ...[
                    _buildYearListView(context, isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatPill({required String label, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String id, String title) {
    final isSelected = _selectedFilter == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = id);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TableCalendar<HolidayData>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableGestures: AvailableGestures.horizontalSwipe,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
          CalendarFormat.twoWeeks: '2 Weeks',
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: _getHolidaysForDay,
        headerStyle: HeaderStyle(
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
          ),
          formatButtonTextStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
          formatButtonDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary(context)),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary(context)),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : AppColors.grey800,
            fontWeight: FontWeight.w500,
          ),
          weekendTextStyle: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final hols = _getHolidaysForDay(day);
            if (hols.isNotEmpty) {
              final isNational = hols.any((h) => h.type == 'national');
              final badgeColor = isNational ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B);

              return Container(
                margin: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }
            return null;
          },
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((e) {
                    final isNat = e.type == 'national';
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isNat ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDaySection(BuildContext context, bool isDark, List<HolidayData> holidays) {
    final dateFormatted = _selectedDay != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!)
        : 'Selected Date';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              if (holidays.isEmpty)
                TextButton.icon(
                  onPressed: () => _showForm(null, _selectedDay),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Holiday', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (holidays.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 32,
                      color: AppColors.textSecondary(context).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No holidays scheduled on this day',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...holidays.map((h) => _buildHolidayCard(context, h, isDark)),
        ],
      ),
    );
  }

  Widget _buildYearListView(BuildContext context, bool isDark) {
    final holidays = _filteredHolidays;

    if (holidays.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.event_busy_rounded, size: 40, color: Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              Text(
                'No holidays match your filter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the "+" button at top to add one',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(context)),
              ),
            ],
          ),
        ),
      );
    }

    // Group by month
    final Map<int, List<HolidayData>> grouped = {};
    for (final h in holidays) {
      final parsed = DateTime.tryParse(h.date);
      if (parsed != null) {
        grouped.putIfAbsent(parsed.month, () => []).add(h);
      }
    }

    return Column(
      children: grouped.entries.map((entry) {
        final monthName = DateFormat('MMMM').format(DateTime(2026, entry.key, 1));
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$monthName (${entry.value.length})',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((h) => _buildHolidayCard(context, h, isDark)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHolidayCard(BuildContext context, HolidayData h, bool isDark) {
    final isNational = h.type == 'national';
    final accentColor = isNational ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B);
    final parsedDate = DateTime.tryParse(h.date);
    final dayNum = parsedDate != null ? DateFormat('dd').format(parsedDate) : '??';
    final weekday = parsedDate != null ? DateFormat('EEE').format(parsedDate) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Day Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    weekday.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Holiday Name & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          h.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isNational ? '🇰🇭 National' : '🏢 Company',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        h.date,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (h.isRecurring) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Annual',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (h.description != null && h.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      h.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(context).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Quick Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  color: AppColors.textSecondary(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showForm(h),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  color: AppColors.danger.withValues(alpha: 0.8),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _confirmDelete(h.id, h.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
