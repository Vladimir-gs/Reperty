import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../core/utils/code_generator.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/group_models.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(firestoreProvider));
});

/// Grupos a los que pertenece el usuario actual (collectionGroup members).
final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(groupsRepositoryProvider).watchMyGroups(user.uid);
});

/// Grupo seleccionado actualmente (persiste solo en memoria por sesión).
final selectedGroupProvider = StateProvider<Group?>((ref) => null);

/// Miembros del grupo seleccionado.
final groupMembersProvider =
    StreamProvider.autoDispose.family<List<GroupMember>, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).watchMembers(groupId);
});

class GroupsRepository {
  GroupsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');

  /// Grupos del usuario desde su índice propio (users/{uid}/groups).
  /// Evita collectionGroup queries, que las reglas rechazarían por
  /// incluir membresías de otros usuarios.
  Stream<List<Group>> watchMyGroups(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('groups')
        .snapshots()
        .asyncMap((snap) async {
      final groups = <Group>[];
      for (final m in snap.docs) {
        final groupId = (m.data()['groupId'] as String?) ?? m.id;
        final g = await _groups.doc(groupId).get(
              const GetOptions(source: Source.serverAndCache),
            );
        if (g.exists) groups.add(Group.fromDoc(g));
      }
      return groups;
    });
  }

  Stream<List<GroupMember>> watchMembers(String groupId) {
    return _groups
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((s) => s.docs.map(GroupMember.fromDoc).toList());
  }

  /// Crea grupo + membresía owner + mapa de código + índice propio.
  /// Todo en un batch (atómico, funciona offline). La unicidad del código
  /// se verifica con get directo a groupCodes/{code} (permitido por reglas).
  Future<Group> createGroup({
    required String name,
    String description = '',
    required String createdBy,
    String? displayName,
  }) async {
    final ref = _groups.doc();
    final now = DateTime.now();
    var code = CodeGenerator.groupCode();
    for (var i = 0; i < 5; i++) {
      final existing = await _db.collection('groupCodes').doc(code).get();
      if (!existing.exists) break;
      code = CodeGenerator.groupCode();
    }
    final group = Group(
      id: ref.id,
      name: name.trim(),
      description: description.trim(),
      code: code,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
    final batch = _db.batch();
    batch.set(ref, group.toMap());
    batch.set(
      _db.collection('groupCodes').doc(code),
      {'groupId': ref.id, 'name': group.name},
    );
    batch.set(
      ref.collection('members').doc(createdBy),
      GroupMember(
        userId: createdBy,
        role: 'owner',
        musicalRoles: const [],
        joinedAt: now,
        displayName: displayName,
      ).toMap(),
    );
    batch.set(
      _db.collection('users').doc(createdBy).collection('groups').doc(ref.id),
      {
        'groupId': ref.id,
        'name': group.name,
        'code': code,
        'role': 'owner',
        'joinedAt': Timestamp.fromDate(now),
      },
    );
    await batch.commit();
    return group;
  }

  /// Unirse mediante código corto. Resuelve groupCodes/{code} con get
  /// directo (única lectura permitida sin ser miembro) y luego crea la
  /// membresía propia, lo que habilita el resto de lecturas.
  Future<Group> joinByCode({
    required String code,
    required String uid,
    String? displayName,
  }) async {
    final normalized = code.trim().toUpperCase();
    final codeDoc =
        await _db.collection('groupCodes').doc(normalized).get();
    if (!codeDoc.exists) throw StateError('Código no encontrado');
    final groupId = (codeDoc.data()?['groupId'] as String?) ?? '';
    if (groupId.isEmpty) throw StateError('Código inválido');
    final now = DateTime.now();
    final batch = _db.batch();
    batch.set(
      _groups.doc(groupId).collection('members').doc(uid),
      GroupMember(
        userId: uid,
        role: 'member',
        musicalRoles: const [],
        joinedAt: now,
        displayName: displayName,
      ).toMap(),
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('users').doc(uid).collection('groups').doc(groupId),
      {
        'groupId': groupId,
        'name': (codeDoc.data()?['name'] as String?) ?? '',
        'code': normalized,
        'role': 'member',
        'joinedAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    final g = await _groups.doc(groupId).get();
    if (!g.exists) throw StateError('Grupo no encontrado');
    return Group.fromDoc(g);
  }

  Future<void> leaveGroup(String groupId, String uid) async {
    final batch = _db.batch();
    batch.delete(_groups.doc(groupId).collection('members').doc(uid));
    batch.delete(_db.collection('users').doc(uid).collection('groups').doc(groupId));
    await batch.commit();
  }

  Future<void> updateMember(
    String groupId,
    GroupMember member,
  ) async {
    await _groups
        .doc(groupId)
        .collection('members')
        .doc(member.userId)
        .update(member.toMap());
  }

  Future<void> removeMember(String groupId, String uid) async {
    await _groups.doc(groupId).collection('members').doc(uid).delete();
  }
}
