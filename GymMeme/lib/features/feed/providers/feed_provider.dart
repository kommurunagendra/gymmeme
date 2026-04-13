import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/meme_model.dart';
import '../../../data/remote/firestore_service.dart';
import '../../../services/auth_service.dart';

final publicMemesProvider =
    FutureProvider<List<MemeModel>>((ref) async {
  final svc = ref.watch(firestoreServiceProvider);
  return svc.getPublicMemes();
});

final feedNotifierProvider =
    Provider<FeedNotifier>((ref) => FeedNotifier(
          firestoreService: ref.watch(firestoreServiceProvider),
          authService: ref.watch(authServiceProvider),
        ));

class FeedNotifier {
  final FirestoreService firestoreService;
  final AuthService authService;

  FeedNotifier(
      {required this.firestoreService, required this.authService});

  Future<void> upvote(String memeId) =>
      firestoreService.upvoteMeme(memeId);

  Future<void> report({
    required String memeId,
    required String category,
    String? note,
  }) =>
      firestoreService.reportMeme(
        memeId: memeId,
        reporterId: authService.userId ?? 'anonymous',
        category: category,
        note: note,
      );
}
