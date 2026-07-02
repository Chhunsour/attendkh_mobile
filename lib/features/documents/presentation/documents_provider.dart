import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/documents/data/documents_repository.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) => DocumentsRepository());
final documentsProvider = FutureProvider.autoDispose<List<DocumentData>>((ref) async {
  return ref.watch(documentsRepositoryProvider).getDocuments();
});