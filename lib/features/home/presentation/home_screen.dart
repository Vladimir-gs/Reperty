import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../../setlists/data/setlists_repository.dart';
import '../../songs/data/songs_repository.dart';

/// Home: saludo, grupo seleccionado, próximo setlist, conteos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final group = ref.watch(selectedGroupProvider);
    final myGroups = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reperty'),
        actions: [
          IconButton(
            tooltip: 'Cambiar grupo',
            onPressed: () => _showSwitchGroup(context, ref),
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profile.when(
            loading: () => const LoadingView(),
            error: (e, _) => Text('Error: $e'),
            data: (user) => Text(
              user == null ? 'Hola' : 'Hola, ${user.name}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 4),
          myGroups.when(
            loading: () => const Text('Cargando grupos...'),
            error: (e, _) => Text('Error: $e'),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  title: 'Crea o únete a un grupo para empezar.',
                  action: FilledButton(
                    onPressed: () => context.go('/groups'),
                    child: const Text('Ir a grupos'),
                  ),
                );
              }
              final current = group ?? list.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('Código: ${current.code}'),
                  const SizedBox(height: 16),
                  _NextSetlistCard(groupId: current.id),
                  const SizedBox(height: 16),
                  _CountsRow(groupId: current.id),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/setlists'),
                    child: const Text('Ver setlists'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSwitchGroup(BuildContext context, WidgetRef ref) {
    final groups = ref.read(myGroupsProvider).valueOrNull ?? [];
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cambiar de grupo'),
        children: [
          for (final g in groups)
            SimpleDialogOption(
              onPressed: () {
                ref.read(selectedGroupProvider.notifier).state = g;
                Navigator.pop(ctx);
              },
              child: Text(g.name),
            ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.push('/groups');
            },
            child: const Text('Administrar grupos...'),
          ),
        ],
      ),
    );
  }
}

class _NextSetlistCard extends ConsumerWidget {
  const _NextSetlistCard({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setlists = ref.watch(setlistsProvider(groupId));
    return setlists.when(
      loading: () => const Card(child: LoadingView()),
      error: (e, _) => Card(child: ListTile(title: Text('Error: $e'))),
      data: (list) {
        if (list.isEmpty) {
          return const Card(
            child: ListTile(
              title: Text('Próximo setlist'),
              subtitle: Text('Aún no hay setlists.'),
            ),
          );
        }
        final next = list.first;
        return Card(
          child: ListTile(
            title: Text('Próximo: ${next.name}'),
            subtitle: Text(
              next.date != null
                  ? '${next.date!.day}/${next.date!.month}/${next.date!.year}'
                  : next.description,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/setlists/${next.id}'),
          ),
        );
      },
    );
  }
}

class _CountsRow extends ConsumerWidget {
  const _CountsRow({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(groupSongsProvider(groupId));
    final members = ref.watch(groupMembersProvider(groupId));
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    songs.valueOrNull?.length.toString() ?? '—',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text('Canciones'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    members.valueOrNull?.length.toString() ?? '—',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text('Miembros'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
