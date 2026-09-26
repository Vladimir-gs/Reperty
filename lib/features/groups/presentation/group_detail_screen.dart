import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../data/groups_repository.dart';
import '../domain/group_models.dart';

/// Detalle del grupo: código para compartir, miembros y salir.

/// Enlace de invitación. MVP: texto compartible con el código.
/// (La apertura automática del enlace requiere App Links + hosting,
/// pendiente para después del MVP.)
String inviteLinkFor(Group group) =>
    'https://reperty.app/g/${group.code}';

String inviteMessageFor(Group group) =>
    'Únete a "${group.name}" en Reperty.\n'
    'Código: ${group.code}\n'
    '${inviteLinkFor(group)}';

/// Avatar: foto si existe, inicial si no.
class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({this.photoUrl, this.name});

  final String? photoUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final initial = ((name ?? '?').isEmpty ? '?' : name![0]).toUpperCase();
    return CircleAvatar(
      backgroundColor: CupertinoColors.systemGrey5,
      backgroundImage:
          photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null ? Text(initial) : null,
    );
  }
}

/// Detalle del grupo: código para compartir, miembros y salir.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(currentGroupProvider);
    if (group == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LargeTitle(title: 'Grupo'),
                Expanded(
                  child: EmptyState(
                    icon: CupertinoIcons.group,
                    title: 'Selecciona un grupo primero.',
                    action: PrimaryButton(
                      label: 'Ver grupos',
                      onPressed: () => context.go('/groups'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final members = ref.watch(groupMembersProvider(group.id));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              group.name,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            if (group.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  group.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.iosGrey,
                      ),
                ),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradientStrong,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandBlue.withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CÓDIGO PARA INVITAR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.code,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showShare(context, group),
                    child: const Icon(
                      CupertinoIcons.share,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle(title: 'Miembros'),
            members.when(
              loading: () => const LoadingView(),
              error: (e, _) => Text('Error: $e'),
              data: (list) {
                final uid = ref.watch(authStateProvider).valueOrNull?.uid;
                final iAmManager = ref.watch(amManagerProvider(group.id));
                return GroupedSection(
                  children: [
                    for (final m in list)
                      AppleRow(
                        leading: _MemberAvatar(
                          photoUrl: m.photoUrl,
                          name: m.displayName,
                        ),
                        title: m.displayName ?? m.userId,
                        subtitle:
                            '${m.roleLabel}${m.musicalRoles.isEmpty ? '' : ' · ${m.musicalRoles.join(', ')}'}',
                        showChevron: iAmManager && m.userId != uid,
                        onTap: iAmManager && m.userId != uid
                            ? () => _manageMember(
                                  context, ref, group.id, m,
                                  actorUid: uid!, iAmManager: true,
                                )
                            : null,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: CupertinoButton(
                onPressed: () => _confirmLeave(context, ref, group.id),
                child: const Text(
                  'Abandonar grupo',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShare(BuildContext context, Group group) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Invitar a "${group.name}"'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showQr(context, group);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.qrcode, size: 20),
                SizedBox(width: 8),
                Text('Mostrar QR'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Share.share(inviteMessageFor(group));
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.link, size: 20),
                SizedBox(width: 8),
                Text('Enviar enlace'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(text: group.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado')),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.square_on_square, size: 20),
                SizedBox(width: 8),
                Text('Copiar código'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _showQr(BuildContext context, Group group) {
    // Diálogo Material a propósito: QrImageView usa LayoutBuilder interno
    // y CupertinoAlertDialog no soporta dimensiones intrínsecas (crash).
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(group.name, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: inviteLinkFor(group),
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Código ${group.code}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Escanea o comparte el enlace',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Share.share(inviteMessageFor(group));
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _manageMember(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    GroupMember member, {
    required String actorUid,
    required bool iAmManager,
  }) {
    final myRole =
        ref.read(myRoleProvider(groupId)).valueOrNull ?? GroupRoles.member;
    final iAmOwner = myRole == GroupRoles.owner;
    final targetIsSupervisor = member.role == GroupRoles.supervisor;
    final canChangeThisTarget = iAmOwner ||
        (myRole == GroupRoles.supervisor && member.role == GroupRoles.member);
    final canRemoveThisTarget = iAmOwner ||
        (myRole == GroupRoles.supervisor && member.role == GroupRoles.member);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(member.displayName ?? member.userId),
        message: Text('Rol actual: ${member.roleLabel}'),
        actions: [
          if (canChangeThisTarget && !member.isManager)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(ctx);
                await _changeRole(
                  context, ref, groupId, member,
                  GroupRoles.supervisor, actorUid, myRole,
                );
              },
              child: const Text('Hacer supervisor'),
            ),
          if (canChangeThisTarget && targetIsSupervisor)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(ctx);
                await _changeRole(
                  context, ref, groupId, member,
                  GroupRoles.member, actorUid, myRole,
                );
              },
              child: const Text('Volver a miembro'),
            ),
          if (canRemoveThisTarget)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(groupsRepositoryProvider)
                      .removeMember(groupId, member.userId);
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo eliminar: $e')),
                    );
                  }
                }
              },
              child: const Text('Eliminar del grupo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    GroupMember member,
    String newRole,
    String actorUid,
    String actorRole,
  ) async {
    try {
      await ref.read(groupsRepositoryProvider).updateMemberRole(
            groupId: groupId,
            targetUid: member.userId,
            newRole: newRole,
            actorUid: actorUid,
            actorRole: actorRole,
          );
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cambiar el rol: $e')),
        );
      }
    }
  }

  void _confirmLeave(BuildContext context, WidgetRef ref, String groupId) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Abandonar grupo'),
        content: const Text('Dejarás de ver su repertorio y setlists.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final uid = ref.read(authStateProvider).valueOrNull?.uid;
              if (uid == null) return;
              await ref
                  .read(groupsRepositoryProvider)
                  .leaveGroup(groupId, uid);
              ref.read(selectedGroupProvider.notifier).state = null;
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go('/groups');
            },
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
  }
}
