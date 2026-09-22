import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../data/setlists_repository.dart';

class SetlistsScreen extends ConsumerWidget {
  const SetlistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(selectedGroupProvider);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Setlists')),
        body: EmptyState(
          title: 'Selecciona un grupo para ver sus setlists.',
          action: FilledButton(
            onPressed: () => context.go('/groups'),
            child: const Text('Ver grupos'),
          ),
        ),
      );
    }
    final setlists = ref.watch(setlistsProvider(group.id));
    return Scaffold(
      appBar: AppBar(title: Text('Setlists · ${group.name}')),
      body: setlists.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'Sin setlists.\nCrea el primero (ej. Domingo 21).',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(
                    s.date != null
                        ? '${s.date!.day}/${s.date!.month}/${s.date!.year}'
                        : (s.description.isEmpty ? 'Sin fecha' : s.description),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/setlists/${s.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, ref, group.id),
        label: const Text('Nuevo'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref, String groupId) {
    final name = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo setlist'),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(
            labelText: 'Nombre (ej. Domingo 21 Septiembre)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
              await ref.read(setlistsRepositoryProvider).createSetlist(
                    groupId: groupId,
                    name: name.text,
                    date: DateTime.now(),
                    createdBy: uid,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
