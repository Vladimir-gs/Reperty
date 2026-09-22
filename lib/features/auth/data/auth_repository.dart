import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/firestore_service.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    ref.watch(firestoreProvider),
    GoogleSignIn(),
  );
});

/// Stream del usuario autenticado (null si no hay sesión).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Perfil Firestore del usuario actual.
final currentProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(user.uid);
});

class AuthRepository {
  AuthRepository(this._auth, this._db, this._google);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<AppUser?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map(
          (d) => d.exists && d.data() != null
              ? AppUser.fromMap(d.id, d.data()!)
              : null,
        );
  }

  Future<void> _upsertProfile(User user, {String? name}) async {
    final doc = _users.doc(user.uid);
    final now = DateTime.now();
    try {
      // Lectura simple (usa caché offline si no hay red). Si falla por
      // conectividad, se reintenta en el próximo inicio de sesión.
      final existing = await doc.get();
      if (!existing.exists) {
        await doc.set(
          AppUser(
            id: user.uid,
            name: name ?? user.displayName ?? user.email?.split('@').first ?? 'Músico',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            createdAt: now,
            updatedAt: now,
          ).toMap(),
          SetOptions(merge: true),
        );
      }
    } on FirebaseException {
      // Sin conexión o permiso temporal: no bloquear el login.
    }
  }

  Future<User> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _upsertProfile(cred.user!);
    return cred.user!;
  }

  Future<User> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    await _upsertProfile(cred.user!, name: name.trim());
    return cred.user!;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(cred);
    await _upsertProfile(result.user!);
    return result.user;
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}
