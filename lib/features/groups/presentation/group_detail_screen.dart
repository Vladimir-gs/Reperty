import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../data/groups_repository.dart';

/// Detalle del grupo: código para compartir, miembros y salir.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(selectedGroupProvider);
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
                color: AppTheme.iosBlue,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
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
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Código copiado'),
                        ),
                      );
                    },
                    child: const Icon(
                      CupertinoIcons.square_on_square,
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
              data: (list) => GroupedSection(
                children: [
                  for (final m in list)
                    AppleRow(
                      leading: CircleAvatar(
                        backgroundColor: CupertinoColors.systemGrey5,
                        child: Text(
                          ((m.displayName ?? '?').isEmpty
                                  ? '?'
                                  : (m.displayName ?? '?')[0])
                              .toUpperCase(),
                        ),
                      ),
                      title: m.displayName ?? m.userId,
                      subtitle: m.role +
                          (m.musicalRoles.isEmpty
                              ? ''
                              : ' · ${m.musicalRoles.join(', ')}'),
                    ),
                ],
              ),
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
