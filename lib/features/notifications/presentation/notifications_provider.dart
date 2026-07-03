import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/notifications/data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(),
);

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getUnreadCount();
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getAll();
});