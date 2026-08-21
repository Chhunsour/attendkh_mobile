import 'package:flutter_test/flutter_test.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';

void main() {
  test('formatShiftTime compacts the window', () {
    expect(formatShiftTime('09:00:00 - 17:00:00'), '9:00 AM – 5:00 PM');
    expect(formatShiftTime('11:30 - 12:15'), '11:30 AM – 12:15 PM');
  });

  test('shiftEndMinutes reads the end of a shift range', () {
    expect(shiftEndMinutes('08:00 - 17:00'), 17 * 60);
    expect(shiftEndMinutes('08:00:00-17:30:00'), 17 * 60 + 30);
    expect(shiftEndMinutes(null), isNull);
    expect(shiftEndMinutes('No shift today'), isNull);
    expect(shiftEndMinutes('2026-08-19T08:00:00'), isNull);
  });

  test('isLateNow forgives the grace period', () {
    const shift = '08:00 - 17:00';
    expect(isLateNow(shift, 15, now: DateTime(2026, 8, 20, 8, 0)), isFalse);
    expect(isLateNow(shift, 15, now: DateTime(2026, 8, 20, 8, 15)), isFalse);
    expect(isLateNow(shift, 15, now: DateTime(2026, 8, 20, 8, 16)), isTrue);
    expect(isLateNow(shift, 0, now: DateTime(2026, 8, 20, 8, 1)), isTrue);
    expect(isLateNow(shift, 15, now: DateTime(2026, 8, 20, 7, 30)), isFalse);
    // Unreadable window: the server flag decides.
    expect(isLateNow('No shift today', 15, fallback: true), isTrue);
    expect(isLateNow(null, 15), isFalse);
  });

  test('shiftStartMinutes reads the start of a shift range', () {
    expect(shiftStartMinutes('08:00 - 17:00'), 8 * 60);
    expect(shiftStartMinutes('2026-08-19T08:00:00'), isNull);
  });

  test('minutesUntilShiftEnd flags an early clock-out', () {
    const shift = '08:00 - 17:00';
    // Mid-shift: still 90 minutes owed.
    expect(minutesUntilShiftEnd(shift, now: DateTime(2026, 8, 20, 15, 30)), 90);
    // On the dot and after are not early.
    expect(
      minutesUntilShiftEnd(shift, now: DateTime(2026, 8, 20, 17, 0)),
      isNull,
    );
    expect(
      minutesUntilShiftEnd(shift, now: DateTime(2026, 8, 20, 18, 0)),
      isNull,
    );
    // Unreadable window: never block the clock-out on a reason.
    expect(
      minutesUntilShiftEnd(null, now: DateTime(2026, 8, 20, 9, 0)),
      isNull,
    );
    expect(
      minutesUntilShiftEnd('No shift today', now: DateTime(2026, 8, 20, 9, 0)),
      isNull,
    );
  });
}
