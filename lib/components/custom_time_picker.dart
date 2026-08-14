import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay? initialTime;
  final TimeOfDay? disabledStart;
  final TimeOfDay? disabledEnd;

  const CustomTimePicker({
    super.key,
    this.initialTime,
    this.disabledStart,
    this.disabledEnd,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  int? _selectedHour;
  int? _selectedMinute;

  @override
  void initState() {
    super.initState();
    if (widget.initialTime != null) {
      _selectedHour = widget.initialTime!.hour;
      _selectedMinute = _roundToNearest15(widget.initialTime!.minute);
    }
  }

  int _roundToNearest15(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 15;
    if (minute < 38) return 30;
    if (minute < 53) return 45;
    return 0; // Rolls over to 0, ideally we should increment hour, but keeping it simple
  }

  bool _isHourDisabled(int hour) {
    if (widget.disabledStart == null || widget.disabledEnd == null) return false;

    // Shift is within a single day (e.g. 09:00 to 18:00)
    if (widget.disabledStart!.hour < widget.disabledEnd!.hour) {
      // If hour is strictly between start and end, it's completely disabled
      if (hour > widget.disabledStart!.hour && hour < widget.disabledEnd!.hour) return true;
      return false;
    } 
    // Shift goes overnight (e.g. 22:00 to 06:00)
    else {
      if (hour > widget.disabledStart!.hour || hour < widget.disabledEnd!.hour) return true;
      return false;
    }
  }

  bool _isTimeDisabled(int hour, int minute) {
    if (widget.disabledStart == null || widget.disabledEnd == null) return false;

    final timeInMinutes = hour * 60 + minute;
    final startInMinutes = widget.disabledStart!.hour * 60 + widget.disabledStart!.minute;
    final endInMinutes = widget.disabledEnd!.hour * 60 + widget.disabledEnd!.minute;

    if (startInMinutes < endInMinutes) {
      return timeInMinutes >= startInMinutes && timeInMinutes < endInMinutes;
    } else {
      return timeInMinutes >= startInMinutes || timeInMinutes < endInMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutesList = [0, 15, 30, 45];

    return Container(
      height: 500,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          if (widget.disabledStart != null && widget.disabledEnd != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shift hours (${widget.disabledStart!.format(context)} - ${widget.disabledEnd!.format(context)}) are disabled.',
                        style: const TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // Hours List
                Expanded(
                  child: Column(
                    children: [
                      const Text('Hour', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 24,
                          itemBuilder: (context, index) {
                            final hour = index;
                            final isDisabled = _isHourDisabled(hour);
                            final isSelected = _selectedHour == hour;

                            return InkWell(
                              onTap: isDisabled
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedHour = hour;
                                        // Reset minute if invalid combination
                                        if (_selectedMinute != null && _isTimeDisabled(hour, _selectedMinute!)) {
                                          _selectedMinute = null;
                                        }
                                      });
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                color: isSelected ? AppColors.primary.withAlpha(30) : null,
                                child: Center(
                                  child: Text(
                                    hour.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isDisabled
                                          ? Colors.grey.withAlpha(100)
                                          : isSelected
                                              ? AppColors.primary
                                              : AppColors.grey900,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, color: Colors.grey.withAlpha(50)),
                // Minutes List
                Expanded(
                  child: Column(
                    children: [
                      const Text('Minute', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _selectedHour == null
                            ? const Center(child: Text('Select hour first', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: minutesList.length,
                                itemBuilder: (context, index) {
                                  final minute = minutesList[index];
                                  final isDisabled = _isTimeDisabled(_selectedHour!, minute);
                                  final isSelected = _selectedMinute == minute;

                                  return InkWell(
                                    onTap: isDisabled
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedMinute = minute;
                                            });
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      color: isSelected ? AppColors.primary.withAlpha(30) : null,
                                      child: Center(
                                        child: Text(
                                          minute.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isDisabled
                                                ? Colors.grey.withAlpha(100)
                                                : isSelected
                                                    ? AppColors.primary
                                                    : AppColors.grey900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedHour != null && _selectedMinute != null
                    ? () {
                        Navigator.pop(
                          context,
                          TimeOfDay(hour: _selectedHour!, minute: _selectedMinute!),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withAlpha(50),
                ),
                child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  TimeOfDay? initialTime,
  TimeOfDay? disabledStart,
  TimeOfDay? disabledEnd,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CustomTimePicker(
      initialTime: initialTime,
      disabledStart: disabledStart,
      disabledEnd: disabledEnd,
    ),
  );
}
