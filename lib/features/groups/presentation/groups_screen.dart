import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../data/groups_repository.dart';

/// Mis grupos + crear / unirse con código.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showJoinOrCreate(context, ref),
        child: const Icon(CupertinoIcons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LargeTitle(
                title: 'Grupos',
                subtitle: 'Tus ministerios y bandas',
              ),
              Expanded(
                child: groups.when(
                  loading: () => const LoadingView(),
                  error: (_, __) => EmptyState(
                    icon: CupertinoIcons.exclamationmark_circle,
                    title:
                        'No se pudieron cargar tus grupos.\nRevisa tu conexión.',
                    action: PrimaryButton(
                      label: 'Reintentar',
                      onPressed: () => ref.invalidate(myGroupsProvider),
                    ),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return EmptyState(
                        icon: CupertinoIcons.group,
                        title:
                            'Aún no perteneces a ningún grupo.\nCrea uno o únete con un código.',
                        action: PrimaryButton(
                          label: 'Comenzar',
                          onPressed: () => _showJoinOrCreate(context, ref),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: GroupedSection(
                        children: [
                        for (final g in list)
                          AppleRow(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  g.name.isEmpty
                                      ? '?'
                                      : g.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            title: g.name,
                            subtitle: 'Código ${g.code}',
                            showChevron: true,
                            onTap: () {
                              ref
                                  .read(selectedGroupProvider.notifier)
                                  .state = g;
                              context.go('/group');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinOrCreate(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showCreate(context, ref);
            },
            child: const Text('Crear grupo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showJoin(context, ref);
            },
            child: const Text('Unirme con código'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final desc = TextEditingController();
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Nuevo grupo'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: name,
              placeholder: 'Ministerio de Alabanza',
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: desc,
              placeholder: 'Descripción (opcional)',
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final user = ref.read(authStateProvider).valueOrNull;
              if (user == null || name.text.trim().isEmpty) return;
              try {
                final group = await ref
                    .read(groupsRepositoryProvider)
                    .createGroup(
                      name: name.text,
                      description: desc.text,
                      createdBy: user.uid,
                      displayName: user.displayName,
                      photoUrl: user.photoURL,
                    );
                ref.read(selectedGroupProvider.notifier).state = group;
                if (ctx.mounted) Navigator.pop(ctx);
              } on Exception catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo crear: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showJoin(BuildContext context, WidgetRef ref) {
    final code = TextEditingController();
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Unirse a un grupo'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: code,
              placeholder: 'AB72K',
              textCapitalization: TextCapitalization.characters,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final user = ref.read(authStateProvider).valueOrNull;
              if (user == null) return;
              try {
                final group = await ref
                    .read(groupsRepositoryProvider)
                    .joinByCode(
                      code: code.text,
                      uid: user.uid,
                      displayName: user.displayName,
                      photoUrl: user.photoURL,
                    );
                ref.read(selectedGroupProvider.notifier).state = group;
                if (ctx.mounted) Navigator.pop(ctx);
              } on Exception catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo unir: $e')),
                  );
                }
              }
            },
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
  }
}
