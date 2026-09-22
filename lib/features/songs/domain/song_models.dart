import 'package:cloud_firestore/cloud_firestore.dart';

/// Canción canónica global (catálogo compartido).
class Song {
  const Song({
    required this.id,
    required this.title,
    this.artist = '',
    required this.originalKey,
    this.bpm,
    this.notes = '',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String artist;
  final String originalKey;
  final int? bpm;
  final String notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Song.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    DateTime parse(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();
    return Song(
      id: doc.id,
      title: (m['title'] as String?) ?? '',
      artist: (m['artist'] as String?) ?? '',
      originalKey: (m['originalKey'] as String?) ?? 'C',
      bpm: (m['bpm'] as num?)?.toInt(),
      notes: (m['notes'] as String?) ?? '',
      createdBy: (m['createdBy'] as String?) ?? '',
      createdAt: parse(m['createdAt']),
      updatedAt: parse(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'artist': artist,
        'originalKey': originalKey,
        'bpm': bpm,
        'notes': notes,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// Canción dentro del repertorio de un grupo.
/// Denormaliza título/artista/tono para lecturas simples offline.
class GroupSong {
  const GroupSong({
    required this.songId,
    required this.title,
    this.artist = '',
    required this.originalKey,
    required this.addedBy,
    required this.addedAt,
    required this.updatedAt,
  });

  final String songId;
  final String title;
  final String artist;
  final String originalKey;
  final String addedBy;
  final DateTime addedAt;
  final DateTime updatedAt;

  factory GroupSong.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    DateTime parse(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();
    return GroupSong(
      songId: (m['songId'] as String?) ?? doc.id,
      title: (m['title'] as String?) ?? '',
      artist: (m['artist'] as String?) ?? '',
      originalKey: (m['originalKey'] as String?) ?? 'C',
      addedBy: (m['addedBy'] as String?) ?? '',
      addedAt: parse(m['addedAt']),
      updatedAt: parse(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'songId': songId,
        'title': title,
        'artist': artist,
        'originalKey': originalKey,
        'addedBy': addedBy,
        'addedAt': Timestamp.fromDate(addedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// Tono habitual de un vocalista para una canción del grupo.
/// Vive en groups/{g}/songs/{s}/keys/{userId}.
class VocalistKey {
  const VocalistKey({
    required this.userId,
    required this.key,
    this.notes = '',
    required this.updatedAt,
  });

  final String userId;
  final String key;
  final String notes;
  final DateTime updatedAt;

  factory VocalistKey.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final ts = m['updatedAt'];
    return VocalistKey(
      userId: (m['userId'] as String?) ?? doc.id,
      key: (m['key'] as String?) ?? 'C',
      notes: (m['notes'] as String?) ?? '',
      updatedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'key': key,
        'notes': notes,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
