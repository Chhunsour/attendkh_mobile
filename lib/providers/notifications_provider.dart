import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(),
);

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final sub = FcmService.instance.onMessageStream.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => sub.cancel());

  return repo.getUnreadCount();
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final sub = FcmService.instance.onMessageStream.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => sub.cancel());

  return repo.getAll();
});