import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider<ProfileData>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});