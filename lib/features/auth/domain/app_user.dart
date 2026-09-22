import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil básico del usuario. El uid de Firebase Auth es el id.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    DateTime parse(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return AppUser(
      id: id,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: parse(map['createdAt']),
      updatedAt: parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
