import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meme_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User ──────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) => _db
      .collection(AppConstants.usersCollection)
      .doc(user.userId)
      .set(user.toMap(), SetOptions(merge: true));

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateArchetype(String userId, String archetypeId) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .update({'primaryArchetype': archetypeId});

  Future<void> incrementMemeCount(String userId) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .update({'memeCount': FieldValue.increment(1)});

  // ── Memes ─────────────────────────────────────────────────────────────────

  Future<void> saveMeme(MemeModel meme) => _db
      .collection(AppConstants.memesCollection)
      .doc(meme.memeId)
      .set(meme.toMap());

  Future<List<MemeModel>> getPublicMemes({int limit = 20}) async {
    final snapshot = await _db
        .collection(AppConstants.memesCollection)
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((d) => MemeModel.fromMap(d.data()))
        .toList();
  }

  Future<void> upvoteMeme(String memeId) => _db
      .collection(AppConstants.memesCollection)
      .doc(memeId)
      .update({'upvotes': FieldValue.increment(1)});

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<void> reportMeme({
    required String memeId,
    required String reporterId,
    required String category,
    String? note,
  }) async {
    final batch = _db.batch();

    // Create report document
    final reportRef = _db.collection(AppConstants.reportsCollection).doc();
    batch.set(reportRef, {
      'memeId': memeId,
      'reporterId': reporterId,
      'category': category,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment report count on meme
    final memeRef =
        _db.collection(AppConstants.memesCollection).doc(memeId);
    batch.update(memeRef, {'reportCount': FieldValue.increment(1)});

    await batch.commit();

    // Auto-hide at threshold (Cloud Function handles this in production,
    // but we also do it client-side for immediate UX)
    final memeDoc = await memeRef.get();
    final count = memeDoc.data()?['reportCount'] as int? ?? 0;
    if (count >= AppConstants.reportThreshold) {
      await memeRef.update({'status': 'under_review'});
    }
  }
}
