import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/musical_key.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../data/songs_repository.dart';

/// Pantalla Songs: buscar, agregar, ver tono original.
class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(selectedGroupProvider);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Canciones')),
        body: EmptyState(
          title: 'Selecciona un grupo para ver su repertorio.',
          action: FilledButton(
            onPressed: () => context.go('/groups'),
            child: const Text('Ver grupos'),
          ),
        ),
      );
    }
    final songs = ref.watch(groupSongsProvider(group.id));
    return Scaffold(
      appBar: AppBar(title: Text('Canciones · ${group.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Buscar canción...',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: songs.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final filtered = list
                    .where((s) => s.title.toLowerCase().contains(_query))
                    .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'Sin canciones.\nAgrega la primera del repertorio.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(s.title),
                        subtitle: Text(
                          s.artist.isEmpty ? 'Sin artista' : s.artist,
                        ),
                        trailing: KeyBadge(musicalKey: s.originalKey),
                        onTap: () =>
                            context.go('/songs/${s.songId}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context, ref, group.id),
        label: const Text('Agregar'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAdd(BuildContext context, WidgetRef ref, String groupId) {
    final title = TextEditingController();
    final artist = TextEditingController();
    final key = TextEditingController(text: 'C');
    final form = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva canción'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => Validators.required(v),
              ),
              TextFormField(
                controller: artist,
                decoration: const InputDecoration(labelText: 'Artista'),
              ),
              DropdownButtonFormField<String>(
                initialValue: key.text,
                decoration: const InputDecoration(labelText: 'Tono original'),
                items: [
                  for (final k in MusicalKey.allSharpNames)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) {
                  if (v != null) key.text = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final uid = ref.read(authStateProvider).valueOrNull?.uid;
              if (uid == null) return;
              await ref.read(songsRepositoryProvider).addSongToGroup(
                    groupId: groupId,
                    title: title.text,
                    artist: artist.text,
                    originalKey: key.text,
                    addedBy: uid,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
