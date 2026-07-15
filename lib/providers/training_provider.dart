import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/performance_repository.dart';

final performanceRepoProvider = Provider((ref) => PerformanceRepository());

// Available Trainings Provider
final availableTrainingsProvider = FutureProvider.autoDispose<List<TrainingCourseData>>((ref) async {
  final repo = ref.watch(performanceRepoProvider);
  return repo.getAvailableTrainings();
});

// My Active Enrollments Provider
final myTrainingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(performanceRepoProvider);
  return repo.getMyTrainings();
});
