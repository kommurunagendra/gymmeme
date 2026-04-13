import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/database.dart';
import '../../../data/models/meme_model.dart';
import '../../../data/remote/firestore_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import 'package:drift/drift.dart' show Value;

// ─── Draft meme being edited in canvas ───────────────────────────────────────

class DraftMemeState {
  final String? templatePath;
  final String? imagePath;
  final String topCaption;
  final String bottomCaption;
  final double fontSize;
  final String archetypeTag;

  const DraftMemeState({
    this.templatePath,
    this.imagePath,
    this.topCaption = '',
    this.bottomCaption = '',
    this.fontSize = 28,
    this.archetypeTag = '',
  });

  DraftMemeState copyWith({
    String? templatePath,
    String? imagePath,
    String? topCaption,
    String? bottomCaption,
    double? fontSize,
    String? archetypeTag,
  }) =>
      DraftMemeState(
        templatePath: templatePath ?? this.templatePath,
        imagePath: imagePath ?? this.imagePath,
        topCaption: topCaption ?? this.topCaption,
        bottomCaption: bottomCaption ?? this.bottomCaption,
        fontSize: fontSize ?? this.fontSize,
        archetypeTag: archetypeTag ?? this.archetypeTag,
      );
}

final draftMemeProvider =
    StateNotifierProvider.autoDispose<DraftMemeNotifier, DraftMemeState>(
        (_) => DraftMemeNotifier());

class DraftMemeNotifier extends StateNotifier<DraftMemeState> {
  DraftMemeNotifier() : super(const DraftMemeState());

  void setTemplate(String path) =>
      state = state.copyWith(templatePath: path, imagePath: null);

  void setImage(String path) =>
      state = state.copyWith(imagePath: path, templatePath: null);

  void setTopCaption(String text) =>
      state = state.copyWith(topCaption: text);

  void setBottomCaption(String text) =>
      state = state.copyWith(bottomCaption: text);

  void setFontSize(double size) => state = state.copyWith(fontSize: size);

  void setArchetypeTag(String tag) =>
      state = state.copyWith(archetypeTag: tag);
}

// ─── Save meme to local DB + optionally Firebase ─────────────────────────────

final memeServiceProvider = Provider<MemeService>((ref) => MemeService(
      db: ref.watch(appDatabaseProvider),
      firestoreService: ref.watch(firestoreServiceProvider),
      storageService: StorageService(),
      authService: ref.watch(authServiceProvider),
    ));

class MemeService {
  final AppDatabase db;
  final FirestoreService firestoreService;
  final StorageService storageService;
  final AuthService authService;
  final _uuid = const Uuid();

  MemeService({
    required this.db,
    required this.firestoreService,
    required this.storageService,
    required this.authService,
  });

  /// Save meme locally. If user is authenticated and isPublic=true, also upload.
  Future<String> saveMeme({
    required String localImagePath,
    required String topCaption,
    required String bottomCaption,
    String archetypeTag = '',
    bool isPublic = false,
  }) async {
    final memeId = _uuid.v4();
    final userId = authService.userId ?? 'anonymous';

    // 1. Save to local SQLite
    await db.insertMeme(LocalMemesCompanion(
      memeId: Value(memeId),
      localImagePath: Value(localImagePath),
      captions: Value('$topCaption||$bottomCaption'),
      archetypeTag: Value(archetypeTag.isEmpty ? null : archetypeTag),
      createdAt: Value(DateTime.now().toIso8601String()),
    ));

    // 2. If public and authenticated, upload to Firebase
    if (isPublic && authService.userId != null) {
      _uploadInBackground(
          memeId: memeId,
          localImagePath: localImagePath,
          userId: userId,
          topCaption: topCaption,
          bottomCaption: bottomCaption,
          archetypeTag: archetypeTag);
    }

    return memeId;
  }

  // Fire-and-forget upload
  Future<void> _uploadInBackground({
    required String memeId,
    required String localImagePath,
    required String userId,
    required String topCaption,
    required String bottomCaption,
    required String archetypeTag,
  }) async {
    try {
      final url = await storageService.uploadMemeImage(
        localPath: localImagePath,
        memeId: memeId,
        userId: userId,
      );

      await db.updateMemeUploadStatus(memeId, url);

      final meme = MemeModel(
        memeId: memeId,
        creatorId: userId,
        remoteImageUrl: url,
        captions: [
          MemeCaption(text: topCaption, position: 'top'),
          MemeCaption(text: bottomCaption, position: 'bottom'),
        ],
        archetypeTag: archetypeTag.isEmpty ? null : archetypeTag,
        isPublic: true,
        createdAt: DateTime.now(),
      );

      await firestoreService.saveMeme(meme);
      await firestoreService.incrementMemeCount(userId);
    } catch (_) {
      // Silently fail — local save already succeeded
    }
  }
}
