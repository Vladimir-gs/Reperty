import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../domain/setlist_models.dart';

final setlistsRepositoryProvider = Provider<SetlistsRepository>((ref) {
  return SetlistsRepository(ref.watch(firestoreProvider));
});

final setlistsProvider =
    StreamProvider.autoDispose.family<List<Setlist>, String>((ref, groupId) {
  return ref.watch(setlistsRepositoryProvider).watchSetlists(groupId);
});

final setlistItemsProvider = StreamProvider.autoDispose
    .family<List<SetlistSong>, ({String groupId, String setlistId})>(
        (ref, args) {
  return ref
      .watch(setlistsRepositoryProvider)
      .watchItems(args.groupId, args.setlistId);
});

final setlistProvider = StreamProvider.autoDispose
    .family<Setlist?, ({String groupId, String setlistId})>((ref, args) {
  return ref
      .watch(setlistsRepositoryProvider)
      .watchSetlist(args.groupId, args.setlistId);
});

class SetlistsRepository {
  SetlistsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _setlists(String groupId) =>
      _db.collection('groups').doc(groupId).collection('setlists');

  CollectionReference<Map<String, dynamic>> _items(
    String groupId,
    String setlistId,
  ) =>
      _setlists(groupId).doc(setlistId).collection('items');

  Stream<List<Setlist>> watchSetlists(String groupId) {
    return _setlists(groupId).orderBy('date').snapshots().map(
          (s) => s.docs.map(Setlist.fromDoc).toList(),
        );
  }

  Stream<Setlist?> watchSetlist(String groupId, String setlistId) {
    return _setlists(groupId).doc(setlistId).snapshots().map(
          (d) => d.exists ? Setlist.fromDoc(d) : null,
        );
  }

  Future<void> updateSetlist({
    required String groupId,
    required String setlistId,
    String? name,
    String? description,
    DateTime? date,
  }) async {
    await _setlists(groupId).doc(setlistId).update({
      if (name != null) 'name': name.trim(),
      if (description != null) 'description': description.trim(),
      if (date != null) 'date': Timestamp.fromDate(date),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<SetlistSong>> watchItems(String groupId, String setlistId) {    return _items(groupId, setlistId)
        .orderBy('position')
        .snapshots()
        .map((s) => s.docs.map(SetlistSong.fromDoc).toList());
  }

  Future<String> createSetlist({
    required String groupId,
    required String name,
    String description = '',
    DateTime? date,
    required String createdBy,
  }) async {
    final ref = _setlists(groupId).doc();
    final now = DateTime.now();
    await ref.set(
      Setlist(
        id: ref.id,
        name: name.trim(),
        description: description.trim(),
        date: date,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
    return ref.id;
  }

  /// Agrega canción resolviendo automáticamente el tono del vocalista:
  /// busca groups/{g}/songs/{s}/keys/{singerId}; si no existe usa el original.
  Future<void> addSong({
    required String groupId,
    required String setlistId,
    required String songId,
    required String titleSnapshot,
    required String originalKey,
    String? singerId,
    String? singerNameSnapshot,
    String? overrideKey,
    String notes = '',
  }) async {
    String? baseKey;
    if (singerId != null) {
      final keyDoc = await _db
          .collection('groups')
          .doc(groupId)
          .collection('songs')
          .doc(songId)
          .collection('keys')
          .doc(singerId)
          .get();
      if (keyDoc.exists) {
        baseKey = (keyDoc.data()?['key'] as String?) ?? originalKey;
      } else {
        baseKey = originalKey;
      }
    } else {
      baseKey = originalKey;
    }

    final existing =
        await _items(groupId, setlistId).orderBy('position', descending: true).limit(1).get();
    final nextPos = existing.docs.isEmpty
        ? 0
        : ((existing.docs.first.data()['position'] as num?)?.toInt() ?? -1) + 1;

    await _items(groupId, setlistId).add(
          SetlistSong(
            id: '',
            songId: songId,
            titleSnapshot: titleSnapshot,
            position: nextPos,
            singerId: singerId,
            singerNameSnapshot: singerNameSnapshot,
            baseKeySnapshot: baseKey,
            overrideKey: overrideKey,
            notes: notes,
          ).toMap(),
        );
  }

  /// Reordena: reescribe posiciones según el nuevo orden de ids.
  Future<void> reorder({
    required String groupId,
    required String setlistId,
    required List<String> orderedItemIds,
  }) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedItemIds.length; i++) {
      batch.update(
        _items(groupId, setlistId).doc(orderedItemIds[i]),
        {'position': i},
      );
    }
    await batch.commit();
  }

  Future<void> updateItem({
    required String groupId,
    required String setlistId,
    required String itemId,
    String? singerId,
    String? singerNameSnapshot,
    String? baseKeySnapshot,
    String? overrideKey,
    String? notes,
  }) async {
    await _items(groupId, setlistId).doc(itemId).update({
      if (singerId != null) 'singerId': singerId,
      if (singerNameSnapshot != null) 'singerNameSnapshot': singerNameSnapshot,
      if (baseKeySnapshot != null) 'baseKeySnapshot': baseKeySnapshot,
      'overrideKey': overrideKey,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> removeItem({
    required String groupId,
    required String setlistId,
    required String itemId,
  }) async {
    await _items(groupId, setlistId).doc(itemId).delete();
  }

  Future<void> deleteSetlist(String groupId, String setlistId) async {
    await _setlists(groupId).doc(setlistId).delete();
  }
}
