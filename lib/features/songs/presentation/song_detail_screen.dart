import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/musical_key.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../groups/data/groups_repository.dart';
import '../data/songs_repository.dart';

/// Detalle: tono original + tonos por vocalista (editable).
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(selectedGroupProvider);
    if (group == null) {
      return Scaffold(appBar: AppBar(), body: const LoadingView());
    }
    final songs = ref.watch(groupSongsProvider(group.id));
    final keys = ref.watch(
      vocalistKeysProvider((groupId: group.id, songId: songId)),
    );
    final members = ref.watch(groupMembersProvider(group.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Canción')),
      body: songs.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final song = list.where((s) => s.songId == songId).firstOrNull;
          if (song == null) {
            return const EmptyState(title: 'Canción no encontrada.');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                song.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (song.artist.isNotEmpty) Text(song.artist),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Tono original  '),
                  KeyBadge(musicalKey: song.originalKey, large: true),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Vocalistas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              keys.when(
                loading: () => const LoadingView(),
                error: (e, _) => Text('Error: $e'),
                data: (keyList) {
                  final byUser = {for (final k in keyList) k.userId: k};
                  return members.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => Text('Error: $e'),
                    data: (memberList) {
                      final vocalists = memberList
                          .where((m) => m.musicalRoles.contains('vocalist'))
                          .toList();
                      final shown =
                          vocalists.isEmpty ? memberList : vocalists;
                      if (shown.isEmpty) {
                        return const Text('Sin miembros en el grupo.');
                      }
                      return Column(
                        children: [
                          for (final m in shown)
                            Card(
                              child: ListTile(
                                title: Text(m.displayName ?? m.userId),
                                trailing: KeyBadge(
                                  musicalKey:
                                      byUser[m.userId]?.key ?? '—',
                                ),
                                onTap: () => _editKey(
                                  context,
                                  ref,
                                  group.id,
                                  songId,
                                  m.userId,
                                  byUser[m.userId]?.key ?? song.originalKey,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _editKey(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String songId,
    String userId,
    String current,
  ) {
    var selected = MusicalKey.isValid(current) ? MusicalKey.parse(current).sharpName : 'C';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tono del vocalista'),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          items: [
            for (final k in MusicalKey.allSharpNames)
              DropdownMenuItem(value: k, child: Text(k)),
          ],
          onChanged: (v) {
            if (v != null) selected = v;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(songsRepositoryProvider).setVocalistKey(
                    groupId: groupId,
                    songId: songId,
                    userId: userId,
                    key: selected,
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
