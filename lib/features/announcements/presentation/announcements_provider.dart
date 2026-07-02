import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/announcements/data/announcements_repository.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) => AnnouncementsRepository());
final announcementsProvider = FutureProvider.autoDispose<List<AnnouncementData>>((ref) async {
  return ref.watch(announcementsRepositoryProvider).getAnnouncements();
});