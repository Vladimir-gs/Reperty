import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/musical_key.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../groups/data/groups_repository.dart';
import '../../songs/data/songs_repository.dart';
import '../data/setlists_repository.dart';

/// Detalle del setlist: ordenar, asignar vocalista, override de tono.
class SetlistDetailScreen extends ConsumerWidget {
  const SetlistDetailScreen({super.key, required this.setlistId});

  final String setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(selectedGroupProvider);
    if (group == null) {
      return Scaffold(appBar: AppBar(), body: const LoadingView());
    }
    final items = ref.watch(
      setlistItemsProvider((groupId: group.id, setlistId: setlistId)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Setlist')),
      body: items.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Setlist vacío.\nAgrega canciones del repertorio.',
              action: FilledButton(
                onPressed: () =>
                    _showAddSong(context, ref, group.id, setlistId),
                child: const Text('Agregar canción'),
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            onReorderItem: (oldIndex, newIndex) async {
              final ids = list.map((e) => e.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              await ref.read(setlistsRepositoryProvider).reorder(
                    groupId: group.id,
                    setlistId: setlistId,
                    orderedItemIds: ids,
                  );
            },
            itemBuilder: (context, i) {
              final item = list[i];
              final key = item.effectiveKey ?? '—';
              final isOverride = item.overrideKey != null;
              return Card(
                key: ValueKey(item.id),
                child: ListTile(
                  leading: Text(
                    (i + 1).toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  title: Text(item.titleSnapshot),
                  subtitle: Text(
                    item.singerNameSnapshot ?? 'Sin vocalista',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KeyBadge(musicalKey: key),
                      if (isOverride)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.push_pin, size: 16),
                        ),
                    ],
                  ),
                  onTap: () => _showEditItem(
                    context,
                    ref,
                    group.id,
                    setlistId,
                    item.id,
                    item.overrideKey,
                  ),
                  onLongPress: () => ref
                      .read(setlistsRepositoryProvider)
                      .removeItem(
                        groupId: group.id,
                        setlistId: setlistId,
                        itemId: item.id,
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSong(context, ref, group.id, setlistId),
        label: const Text('Agregar'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSong(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String setlistId,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final songs = ref.watch(groupSongsProvider(groupId));
        final members = ref.watch(groupMembersProvider(groupId));
        String? songId;
        String? singerId;
        return AlertDialog(
          title: const Text('Agregar al setlist'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                songs.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) => DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Canción'),
                    items: [
                      for (final s in list)
                        DropdownMenuItem(
                          value: s.songId,
                          child: Text('${s.title} · ${s.originalKey}'),
                        ),
                    ],
                    onChanged: (v) => songId = v,
                  ),
                ),
                members.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) => DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Vocalista'),
                    items: [
                      for (final m in list)
                        DropdownMenuItem(
                          value: m.userId,
                          child: Text(m.displayName ?? m.userId),
                        ),
                    ],
                    onChanged: (v) => singerId = v,
                  ),
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
                if (songId == null) return;
                final allSongs =
                    ref.read(groupSongsProvider(groupId)).valueOrNull ?? [];
                final song =
                    allSongs.where((s) => s.songId == songId).firstOrNull;
                if (song == null) return;
                final allMembers =
                    ref.read(groupMembersProvider(groupId)).valueOrNull ?? [];
                final singer = allMembers
                    .where((m) => m.userId == singerId)
                    .firstOrNull;
                await ref.read(setlistsRepositoryProvider).addSong(
                      groupId: groupId,
                      setlistId: setlistId,
                      songId: song.songId,
                      titleSnapshot: song.title,
                      originalKey: song.originalKey,
                      singerId: singerId,
                      singerNameSnapshot: singer?.displayName,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditItem(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String setlistId,
    String itemId,
    String? currentOverride,
  ) {
    String? selected = currentOverride;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tono para este servicio'),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: const InputDecoration(
            labelText: 'Override (vacío = tono habitual)',
          ),
          items: [
            for (final k in MusicalKey.allSharpNames)
              DropdownMenuItem(value: k, child: Text(k)),
          ],
          onChanged: (v) => selected = v,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Quitar override.
              await ref.read(setlistsRepositoryProvider).updateItem(
                    groupId: groupId,
                    setlistId: setlistId,
                    itemId: itemId,
                    overrideKey: null,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Usar habitual'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(setlistsRepositoryProvider).updateItem(
                    groupId: groupId,
                    setlistId: setlistId,
                    itemId: itemId,
                    overrideKey: selected,
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
