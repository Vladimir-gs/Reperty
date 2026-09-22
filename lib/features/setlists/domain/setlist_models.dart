import 'package:cloud_firestore/cloud_firestore.dart';

/// Setlist de un grupo (p. ej. Domingo 21 Septiembre).
class Setlist {
  const Setlist({
    required this.id,
    required this.name,
    this.description = '',
    this.date,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime? date;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Setlist.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    DateTime parse(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();
    final d = m['date'];
    return Setlist(
      id: doc.id,
      name: (m['name'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      date: d is Timestamp ? d.toDate() : null,
      createdBy: (m['createdBy'] as String?) ?? '',
      createdAt: parse(m['createdAt']),
      updatedAt: parse(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'date': date != null ? Timestamp.fromDate(date!) : null,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// Canción dentro de un setlist.
///
/// - [singerId]: vocalista asignado (nullable).
/// - [overrideKey]: tono manual para esta presentación; si es null se usa
///   el tono habitual del vocalista (o el original si no hay).
class SetlistSong {
  const SetlistSong({
    required this.id,
    required this.songId,
    required this.titleSnapshot,
    required this.position,
    this.singerId,
    this.singerNameSnapshot,
    this.baseKeySnapshot,
    this.overrideKey,
    this.notes = '',
  });

  final String id;
  final String songId;
  final String titleSnapshot;
  final int position;
  final String? singerId;
  final String? singerNameSnapshot;
  final String? baseKeySnapshot;
  final String? overrideKey;
  final String notes;

  /// Tono efectivo a mostrar: override > base del vocalista > original.
  String? get effectiveKey => overrideKey ?? baseKeySnapshot;

  factory SetlistSong.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return SetlistSong(
      id: doc.id,
      songId: (m['songId'] as String?) ?? '',
      titleSnapshot: (m['titleSnapshot'] as String?) ?? '',
      position: (m['position'] as num?)?.toInt() ?? 0,
      singerId: m['singerId'] as String?,
      singerNameSnapshot: m['singerNameSnapshot'] as String?,
      baseKeySnapshot: m['baseKeySnapshot'] as String?,
      overrideKey: m['overrideKey'] as String?,
      notes: (m['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'songId': songId,
        'titleSnapshot': titleSnapshot,
        'position': position,
        'singerId': singerId,
        'singerNameSnapshot': singerNameSnapshot,
        'baseKeySnapshot': baseKeySnapshot,
        'overrideKey': overrideKey,
        'notes': notes,
      };
}
