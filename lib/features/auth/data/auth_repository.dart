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

/// Perfil Firestore del usuario actual (se auto-crea si falta).
final currentProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfileEnsured(user);
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

  /// Observa el perfil garantizando que el documento exista.
  /// Si falta (p. ej. se creó la cuenta sin red), lo crea desde Firebase Auth.
  Stream<AppUser?> watchProfileEnsured(User user) async* {
    await ensureProfile(user);
    yield* watchProfile(user.uid);
  }

  Future<void> ensureProfile(User user, {String? name}) async {
    final doc = _users.doc(user.uid);
    final now = DateTime.now();
    try {
      final existing = await doc.get();
      await doc.set(
        AppUser(
          id: user.uid,
          name: name ??
              (existing.data()?['name'] as String?) ??
              user.displayName ??
              user.email?.split('@').first ??
              'Músico',
          email: user.email ?? (existing.data()?['email'] as String?) ?? '',
          photoUrl: user.photoURL ?? existing.data()?['photoUrl'] as String?,
          createdAt: (existing.data()?['createdAt'] as Timestamp?)?.toDate() ?? now,
          updatedAt: now,
        ).toMap(),
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // Sin conexión: se reintentará al reabrir el perfil.
    }
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

  /// Propaga nombre/foto actuales a mis membresías de grupo,
  /// para que los avatares se vean en todos lados.
  Future<void> syncMemberPresence(User user) async {
    try {
      final index =
          await _db.collection('users').doc(user.uid).collection('groups').get();
      final batch = _db.batch();
      var count = 0;
      for (final doc in index.docs) {
        final groupId = (doc.data()['groupId'] as String?) ?? doc.id;
        batch.set(
          _db
              .collection('groups')
              .doc(groupId)
              .collection('members')
              .doc(user.uid),
          {
            'displayName': user.displayName ??
                user.email?.split('@').first ??
                'Músico',
            'photoUrl': user.photoURL,
          },
          SetOptions(merge: true),
        );
        count++;
      }
      if (count > 0) await batch.commit();
    } on FirebaseException {
      // No bloquear el login por esto.
    }
  }

  Future<User> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _upsertProfile(cred.user!);
    await syncMemberPresence(cred.user!);
    return cred.user!;
  }

  Future<User> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    await _upsertProfile(cred.user!, name: name.trim());
    await syncMemberPresence(cred.user!);
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
    await syncMemberPresence(result.user!);
    return result.user;
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}
