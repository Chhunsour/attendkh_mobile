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
}
