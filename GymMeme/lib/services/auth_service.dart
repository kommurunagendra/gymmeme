import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/remote/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(
      firestoreService: ref.watch(firestoreServiceProvider),
    ));

final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());

// Emits the current Firebase User (null = signed out)
final authStateProvider = StreamProvider<User?>(
    (_) => FirebaseAuth.instance.authStateChanges());

// Resolved GymType user model
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
    data: (user) async {
      if (user == null) return null;
      final svc = ref.read(firestoreServiceProvider);
      return svc.getUser(user.uid);
    },
  );
});

class AuthService {
  final FirestoreService firestoreService;
  AuthService({required this.firestoreService});

  User? get currentUser => FirebaseAuth.instance.currentUser;
  String? get userId => currentUser?.uid;

  /// Sign in anonymously — creates Firestore user doc on first sign-in
  Future<UserModel> signInAnonymously() async {
    final existing = currentUser;
    if (existing != null) {
      return _ensureUserDoc(existing.uid);
    }
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return _ensureUserDoc(cred.user!.uid);
  }

  Future<UserModel> _ensureUserDoc(String uid) async {
    var user = await firestoreService.getUser(uid);
    if (user == null) {
      user = UserModel(
        userId: uid,
        primaryArchetype: 'unknown',
        createdAt: DateTime.now(),
      );
      await firestoreService.createUser(user);
    }
    return user;
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
