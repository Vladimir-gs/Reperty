import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../data/groups_repository.dart';

/// Lista de mis grupos + crear / unirse.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis grupos')),
      body: groups.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Aún no perteneces a ningún grupo.\nCrea uno o únete con un código.',
              action: FilledButton(
                onPressed: () => _showJoinOrCreate(context, ref),
                child: const Text('Comenzar'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final g = list[i];
              return Card(
                child: ListTile(
                  title: Text(g.name),
                  subtitle: Text('Código: ${g.code}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(selectedGroupProvider.notifier).state = g;
                    context.go('/group');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJoinOrCreate(context, ref),
        label: const Text('Unirse / Crear'),
        icon: const Icon(Icons.group_add),
      ),
    );
  }

  void _showJoinOrCreate(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCreate(context, ref);
                },
                child: const Text('Crear grupo'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showJoin(context, ref);
                },
                child: const Text('Unirme con código'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final desc = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
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
                    );
                ref.read(selectedGroupProvider.notifier).state = group;
                if (ctx.mounted) Navigator.pop(ctx);
              } on Exception catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unirse a un grupo'),
        content: TextField(
          controller: code,
          decoration: const InputDecoration(labelText: 'Código (ej. AB72K)'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
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
                    );
                ref.read(selectedGroupProvider.notifier).state = group;
                if (ctx.mounted) Navigator.pop(ctx);
              } on Exception catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
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
