import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../data/groups_repository.dart';

/// Detalle del grupo seleccionado: miembros, código, salir.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(selectedGroupProvider);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grupo')),
        body: EmptyState(
          title: 'Selecciona un grupo primero.',
          action: FilledButton(
            onPressed: () => context.go('/groups'),
            child: const Text('Ver grupos'),
          ),
        ),
      );
    }
    final members = ref.watch(groupMembersProvider(group.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            tooltip: 'Copiar código',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: group.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado')),
              );
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text('Código del grupo: ${group.code}'),
              subtitle: Text(
                group.description.isEmpty ? 'Sin descripción' : group.description,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Miembros',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          members.when(
            loading: () => const LoadingView(),
            error: (e, _) => Text('Error: $e'),
            data: (list) => Column(
              children: [
                for (final m in list)
                  Card(
                    child: ListTile(
                      title: Text(m.displayName ?? m.userId),
                      subtitle: Text(
                        '${m.role}${m.musicalRoles.isEmpty ? '' : ' · ${m.musicalRoles.join(', ')}'}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final uid = ref.read(authStateProvider).valueOrNull?.uid;
              if (uid == null) return;
              await ref
                  .read(groupsRepositoryProvider)
                  .leaveGroup(group.id, uid);
              ref.read(selectedGroupProvider.notifier).state = null;
              if (context.mounted) context.go('/groups');
            },
            child: const Text('Abandonar grupo'),
          ),
        ],
      ),
    );
  }
}
