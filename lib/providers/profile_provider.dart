import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider.autoDispose<ProfileData>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.token == null || authState.token!.isEmpty) {
    return const ProfileData(id: 0, name: 'Unknown', companyId: 0, roles: []);
  }
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});