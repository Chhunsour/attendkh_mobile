import 'package:flutter_test/flutter_test.dart';
import 'package:attendkh/services/admin_operations_repository.dart';

void main() {
  test('action drops the name the message repeats', () {
    final a = RecentActivity.fromJson({
      'type': 'leave',
      'name': 'Vanna Net រស្មី',
      'message': 'Vanna Net រស្មី requested 1.0 days of Annual Leave',
      'time': '2026-08-19 09:00:00',
    });
    expect(a.action, 'requested 1.0 days of Annual Leave');
  });

  test('action keeps the whole message when there is no name prefix', () {
    expect(
      RecentActivity.fromJson({
        'message': 'Payroll run completed',
        'type': 'other',
        'time': '',
      }).action,
      'Payroll run completed',
    );
    expect(
      RecentActivity.fromJson({
        'name': 'Ong Phally',
        'message': 'An expense was submitted by Ong Phally',
        'type': 'expense',
        'time': '',
      }).action,
      'An expense was submitted by Ong Phally',
    );
  });
}
