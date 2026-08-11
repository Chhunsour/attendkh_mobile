import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  State<AdminHolidaysScreen> createState() => _State();
}

class _State extends State<AdminHolidaysScreen> {
  bool _loading = true;
  List<HolidayData> _items = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  List<HolidayData> _getHolidaysForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _items.where((h) => h.date == dateStr).toList();
  }

  void _showForm([HolidayData? item, DateTime? selectedDate]) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: isEdit ? item.name : '');
    final dateCtrl = TextEditingController(text: isEdit ? item.date : (selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate) : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)))));
    final descCtrl = TextEditingController(text: isEdit ? (item.description ?? '') : '');
    String selectedType = isEdit ? item.type : 'company';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final l10n = AppLocalizations.of(ctx)!;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? l10n.editHoliday : l10n.addHoliday, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.holidayNameLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.text),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: l10n.holidayDateLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                      ),
                      onTap: () async {
                        final defaultDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));
                        final initDate = DateTime.tryParse(dateCtrl.text) ?? defaultDate;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(labelText: l10n.holidayTypeLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: [
                        DropdownMenuItem(value: 'company', child: Text(l10n.holidayTypeCompany)),
                        DropdownMenuItem(value: 'national', child: Text(l10n.holidayTypeNational)),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: descCtrl, decoration: InputDecoration(labelText: l10n.holidayDescriptionLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.text),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseFillRequired, style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.danger)); return; }
                          try {
                            if (isEdit) {
                              final data = {
                                'name': nameCtrl.text.trim(),
                                'date': dateCtrl.text.trim(),
                                'type': selectedType,
                                'description': descCtrl.text.trim(),
                              };
                              await AdminOperationsRepository().updateHoliday(item.id, data);
                            } else {
                              await AdminOperationsRepository().createHoliday(name: nameCtrl.text.trim(), date: dateCtrl.text.trim(), type: selectedType, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          } catch (e) {
                            if (!mounted) return;
                            if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                          }
                        },
                        child: Text(isEdit ? l10n.saveChangesBtn : l10n.createHolidayBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      )
    );
  }

  void _confirmDelete(int id, String name) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Delete Holiday?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.grey800,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: "Are you sure you want to delete\n",
                    ),
                    TextSpan(
                      text: '"$name"',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: "?\n\nThis action cannot be undone.",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(
                          color: Colors.grey,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppColors.grey800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);

                        try {
                          await AdminOperationsRepository()
                              .deleteHoliday(id);

                          _fetchData();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("✅ Holiday deleted successfully"),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("❌ $e"),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedHolidays = _selectedDay != null ? _getHolidaysForDay(_selectedDay!) : <HolidayData>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.holidaysTitle, style: const TextStyle(color: AppColors.grey800, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: () => _showForm(null, _selectedDay))
        ],
      ),
      body: _loading
          ? LoadingIndicator(message: l10n.loadingHolidays)
          : Column(
              children: [
                Container(
                  color: AppColors.surfaceLight,
                  child: TableCalendar<HolidayData>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getHolidaysForDay,
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: AppColors.grey800, shape: BoxShape.circle),
                      markerDecoration: BoxDecoration(color: Colors.transparent),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final hols = _getHolidaysForDay(day);
                        if (hols.isNotEmpty) {
                          bool isNational = hols.any((h) => h.type == 'national');
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: isNational ? AppColors.dangerLight : AppColors.infoLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isNational ? AppColors.danger : AppColors.info,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: events.map((e) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                width: 5.0,
                                height: 5.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: e.type == 'national' ? AppColors.danger : AppColors.info,
                                  ),
                              )).toList(),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: selectedHolidays.isEmpty
                      ? Center(child: Text(l10n.noHolidaysOnDay, style: const TextStyle(color: AppColors.grey500)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: selectedHolidays.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final e = selectedHolidays[i];
                            final isNational = e.type == 'national';
                            final bgColor = isNational ? AppColors.dangerLight : AppColors.infoLight;
                            final textColor = isNational ? AppColors.danger : AppColors.info;
                            final borderColor = isNational ? AppColors.danger.withAlpha(80) : AppColors.info.withAlpha(80);

                            return Container(
                              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(child: Text(e.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textColor))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: isNational ? AppColors.danger.withAlpha(40) : AppColors.info.withAlpha(40), borderRadius: BorderRadius.circular(8)),
                                      child: Text(e.type == 'national' ? l10n.nationalBadge : l10n.companyBadge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
                                    ),
                                  ],
                                ),
                                subtitle: e.description?.isNotEmpty == true
                                    ? Text(e.description!, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13))
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: Icon(Icons.edit, color: textColor.withValues(alpha: 0.6), size: 20), onPressed: () => _showForm(e)),
                                    IconButton(icon: Icon(Icons.delete, color: textColor, size: 20), onPressed: () => _confirmDelete(e.id, e.name)),
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
  }
}
