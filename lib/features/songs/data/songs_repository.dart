import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../core/utils/musical_key.dart';
import '../domain/song_models.dart';

final songsRepositoryProvider = Provider<SongsRepository>((ref) {
  return SongsRepository(ref.watch(firestoreProvider));
});

/// Repertorio del grupo seleccionado.
final groupSongsProvider =
    StreamProvider.autoDispose.family<List<GroupSong>, String>((ref, groupId) {
  return ref.watch(songsRepositoryProvider).watchGroupSongs(groupId);
});

/// Tonos por vocalista de una canción del grupo.
final vocalistKeysProvider = StreamProvider.autoDispose
    .family<List<VocalistKey>, ({String groupId, String songId})>((ref, args) {
  return ref
      .watch(songsRepositoryProvider)
      .watchVocalistKeys(args.groupId, args.songId);
});

class SongsRepository {
  SongsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _catalog =>
      _db.collection('songs');

  CollectionReference<Map<String, dynamic>> _groupSongs(String groupId) =>
      _db.collection('groups').doc(groupId).collection('songs');

  Stream<List<GroupSong>> watchGroupSongs(String groupId) {
    return _groupSongs(groupId).orderBy('title').snapshots().map(
          (s) => s.docs.map(GroupSong.fromDoc).toList(),
        );
  }

  Stream<List<VocalistKey>> watchVocalistKeys(String groupId, String songId) {
    return _groupSongs(groupId)
        .doc(songId)
        .collection('keys')
        .snapshots()
        .map((s) => s.docs.map(VocalistKey.fromDoc).toList());
  }

  /// Registra canción en catálogo global y la agrega al grupo (mismo songId).
  Future<String> addSongToGroup({
    required String groupId,
    required String title,
    String artist = '',
    required String originalKey,
    int? bpm,
    String notes = '',
    required String addedBy,
  }) async {
    // Valida tono antes de escribir.
    MusicalKey.parse(originalKey);
    final now = DateTime.now();
    final catalogRef = _catalog.doc();
    final song = Song(
      id: catalogRef.id,
      title: title.trim(),
      artist: artist.trim(),
      originalKey: originalKey.trim(),
      bpm: bpm,
      notes: notes.trim(),
      createdBy: addedBy,
      createdAt: now,
      updatedAt: now,
    );
    final batch = _db.batch();
    batch.set(catalogRef, song.toMap());
    batch.set(
      _groupSongs(groupId).doc(catalogRef.id),
      GroupSong(
        songId: catalogRef.id,
        title: song.title,
        artist: song.artist,
        originalKey: song.originalKey,
        addedBy: addedBy,
        addedAt: now,
        updatedAt: now,
      ).toMap(),
    );
    await batch.commit();
    return catalogRef.id;
  }

  /// Agrega una canción existente del catálogo al grupo (por id).
  Future<void> addExistingToGroup({
    required String groupId,
    required String songId,
    required String addedBy,
  }) async {
    final snap = await _catalog.doc(songId).get();
    if (!snap.exists) throw StateError('Canción no encontrada');
    final song = Song.fromDoc(snap);
    final now = DateTime.now();
    await _groupSongs(groupId).doc(songId).set(
          GroupSong(
            songId: song.id,
            title: song.title,
            artist: song.artist,
            originalKey: song.originalKey,
            addedBy: addedBy,
            addedAt: now,
            updatedAt: now,
          ).toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> setVocalistKey({
    required String groupId,
    required String songId,
    required String userId,
    required String key,
    String notes = '',
  }) async {
    MusicalKey.parse(key);
    await _groupSongs(groupId).doc(songId).collection('keys').doc(userId).set(
          VocalistKey(
            userId: userId,
            key: key.trim(),
            notes: notes,
            updatedAt: DateTime.now(),
          ).toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> removeFromGroup(String groupId, String songId) async {
    await _groupSongs(groupId).doc(songId).delete();
  }
}
