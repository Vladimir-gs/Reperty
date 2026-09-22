import 'package:cloud_firestore/cloud_firestore.dart';

/// Grupo musical (p. ej. Ministerio de Alabanza — Iglesia XYZ).
class Group {
  const Group({
    required this.id,
    required this.name,
    this.description = '',
    required this.code,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String code;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    DateTime parse(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();
    return Group(
      id: doc.id,
      name: (m['name'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      code: (m['code'] as String?) ?? '',
      createdBy: (m['createdBy'] as String?) ?? '',
      createdAt: parse(m['createdAt']),
      updatedAt: parse(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'code': code,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// Membresía: rol administrativo + funciones musicales.
class GroupMember {
  const GroupMember({
    required this.userId,
    required this.role,
    required this.musicalRoles,
    required this.joinedAt,
    this.displayName,
    this.photoUrl,
  });

  final String userId;
  final String role; // owner | admin | member
  final List<String> musicalRoles; // vocalist, guitar, bass, piano, drums, other
  final DateTime joinedAt;
  final String? displayName;
  final String? photoUrl;

  bool get isVocalist => musicalRoles.contains('vocalist');

  factory GroupMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final ts = m['joinedAt'];
    return GroupMember(
      userId: (m['userId'] as String?) ?? doc.id,
      role: (m['role'] as String?) ?? 'member',
      musicalRoles: (m['musicalRoles'] as List?)?.map((e) => '$e').toList() ?? const [],
      joinedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      displayName: m['displayName'] as String?,
      photoUrl: m['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'role': role,
        'musicalRoles': musicalRoles,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'displayName': displayName,
        'photoUrl': photoUrl,
      };
}
