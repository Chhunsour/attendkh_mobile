import 'package:flutter/material.dart';
import 'package:attendkh/utils/theme/theme.dart';

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
  int? _selectedHour; // 1-12
  int? _selectedMinute;
  bool _isPM = false; // AM/PM toggle

  @override
  void initState() {
    super.initState();
    if (widget.initialTime != null) {
      final h = widget.initialTime!.hour;
      _isPM = h >= 12;
      _selectedHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      _selectedMinute = _roundToNearest15(widget.initialTime!.minute);
    }
  }

  int _roundToNearest15(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 15;
    if (minute < 38) return 30;
    if (minute < 53) return 45;
    return 0;
  }

  int get _realHour {
    if (_selectedHour == null) return 0;
    if (_selectedHour == 12) return _isPM ? 12 : 0;
    return _isPM ? _selectedHour! + 12 : _selectedHour!;
  }

  bool _isHourDisabled(int hour12, bool pm) {
    if (widget.disabledStart == null || widget.disabledEnd == null) {
      return false;
    }

    int realHour;
    if (hour12 == 12) {
      realHour = pm ? 12 : 0;
    } else {
      realHour = pm ? hour12 + 12 : hour12;
    }

    if (widget.disabledStart!.hour < widget.disabledEnd!.hour) {
      if (realHour > widget.disabledStart!.hour &&
          realHour < widget.disabledEnd!.hour) {
        return true;
      }
      return false;
    } else {
      if (realHour > widget.disabledStart!.hour ||
          realHour < widget.disabledEnd!.hour) {
        return true;
      }
      return false;
    }
  }

  bool _isTimeDisabled(int realHour, int minute) {
    if (widget.disabledStart == null || widget.disabledEnd == null) {
      return false;
    }

    final timeInMinutes = realHour * 60 + minute;
    final startInMinutes =
        widget.disabledStart!.hour * 60 + widget.disabledStart!.minute;
    final endInMinutes =
        widget.disabledEnd!.hour * 60 + widget.disabledEnd!.minute;

    if (startInMinutes < endInMinutes) {
      return timeInMinutes >= startInMinutes && timeInMinutes < endInMinutes;
    } else {
      return timeInMinutes >= startInMinutes || timeInMinutes < endInMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutesList = [0, 15, 30, 45];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickerHeight = (MediaQuery.sizeOf(context).height * 0.86)
        .clamp(280.0, 500.0)
        .toDouble();

    return Container(
      height: pickerHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textPrimary(context),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
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
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shift hours (${widget.disabledStart!.format(context)} - ${widget.disabledEnd!.format(context)}) are disabled.',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // AM/PM Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPM = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isPM
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.surfaceDarkElevated
                                : AppColors.grey100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'AM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: !_isPM ? Colors.white : AppColors.grey500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPM = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isPM
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.surfaceDarkElevated
                                : AppColors.grey100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'PM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isPM ? Colors.white : AppColors.grey500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // Hours List (1-12)
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Hour',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final hour12 = index + 1;
                            final isDisabled = _isHourDisabled(hour12, _isPM);
                            final isSelected = _selectedHour == hour12;

                            return InkWell(
                              onTap: isDisabled
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedHour = hour12;
                                        if (_selectedMinute != null &&
                                            _isTimeDisabled(
                                              _realHour,
                                              _selectedMinute!,
                                            )) {
                                          _selectedMinute = null;
                                        }
                                      });
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                color: isSelected
                                    ? AppColors.primary.withAlpha(30)
                                    : null,
                                child: Center(
                                  child: Text(
                                    hour12.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isDisabled
                                          ? Colors.grey.withAlpha(100)
                                          : isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? Colors.white
                                              : AppColors.grey900),
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
                      const Text(
                        'Minute',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _selectedHour == null
                            ? const Center(
                                child: Text(
                                  'Select hour first',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: minutesList.length,
                                itemBuilder: (context, index) {
                                  final minute = minutesList[index];
                                  final isDisabled = _isTimeDisabled(
                                    _realHour,
                                    minute,
                                  );
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      color: isSelected
                                          ? AppColors.primary.withAlpha(30)
                                          : null,
                                      child: Center(
                                        child: Text(
                                          minute.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isDisabled
                                                ? Colors.grey.withAlpha(100)
                                                : isSelected
                                                ? AppColors.primary
                                                : (isDark
                                                    ? Colors.white
                                                    : AppColors.grey900),
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
                          TimeOfDay(hour: _realHour, minute: _selectedMinute!),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withAlpha(50),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
