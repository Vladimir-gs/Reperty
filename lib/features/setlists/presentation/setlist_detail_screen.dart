import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/musical_key.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../groups/data/groups_repository.dart';
import '../../songs/data/songs_repository.dart';
import '../data/setlists_repository.dart';

/// Detalle del setlist: orden táctil, vocalista y tono por servicio.
class SetlistDetailScreen extends ConsumerWidget {
  const SetlistDetailScreen({super.key, required this.setlistId});

  final String setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(selectedGroupProvider);
    if (group == null) {
      return const Scaffold(body: LoadingView());
    }
    final items = ref.watch(
      setlistItemsProvider((groupId: group.id, setlistId: setlistId)),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlist'),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => _showAddSong(context, ref, group.id, setlistId),
            child: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body: items.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: CupertinoIcons.list_bullet,
              title: 'Setlist vacío.\nAgrega cantos del repertorio.',
              action: PrimaryButton(
                label: 'Agregar canto',
                onPressed: () =>
                    _showAddSong(context, ref, group.id, setlistId),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Mantén y arrastra para ordenar · toca para ajustar el tono',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    return Container(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                      ),
                      child: AppleRow(
                        leading: Text(
                          (i + 1).toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.iosGrey,
                          ),
                        ),
                        title: item.titleSnapshot,
                        subtitle:
                            '${item.singerNameSnapshot ?? 'Sin vocalista'}${isOverride ? ' · tono de hoy' : ''}',
                        trailing: KeyBadge(musicalKey: key),
                        onTap: () => _showEditItem(
                          context,
                          ref,
                          group.id,
                          setlistId,
                          item.id,
                          item.overrideKey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSong(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String setlistId,
  ) {
    final songs = ref.read(groupSongsProvider(groupId)).valueOrNull ?? [];
    final members = ref.read(groupMembersProvider(groupId)).valueOrNull ?? [];
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero agrega cantos al repertorio del grupo.'),
        ),
      );
      return;
    }
    var songIdx = 0;
    var singerIdx = -1;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: const Text('Agregar al setlist'),
          content: Column(
            children: [
              const SizedBox(height: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _choose(
                  ctx,
                  options: [for (final s in songs) '${s.title} · ${s.originalKey}'],
                  initial: songIdx,
                  onPick: (i) => setDialogState(() => songIdx = i),
                ),
                child: Text(
                  songs[songIdx].title,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _choose(
                  ctx,
                  options: [
                    'Sin vocalista',
                    for (final m in members) m.displayName ?? m.userId,
                  ],
                  initial: singerIdx + 1,
                  onPick: (i) => setDialogState(() => singerIdx = i - 1),
                ),
                child: Text(
                  singerIdx < 0
                      ? 'Sin vocalista'
                      : (members[singerIdx].displayName ??
                          members[singerIdx].userId),
                  style: const TextStyle(fontSize: 15),
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
                final song = songs[songIdx];
                final singer =
                    singerIdx >= 0 ? members[singerIdx] : null;
                await ref.read(setlistsRepositoryProvider).addSong(
                      groupId: groupId,
                      setlistId: setlistId,
                      songId: song.songId,
                      titleSnapshot: song.title,
                      originalKey: song.originalKey,
                      singerId: singer?.userId,
                      singerNameSnapshot: singer?.displayName,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _choose(
    BuildContext context, {
    required List<String> options,
    required int initial,
    required ValueChanged<int> onPick,
  }) {
    var temp = initial.clamp(0, options.length - 1);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: Theme.of(ctx).cardColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  onPressed: () {
                    onPick(temp);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Listo'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController:
                    FixedExtentScrollController(initialItem: temp),
                onSelectedItemChanged: (i) => temp = i,
                children: [for (final o in options) Text(o)],
              ),
            ),
          ],
        ),
      ),
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
    var temp = currentOverride ?? 'C';
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 320,
        color: Theme.of(ctx).cardColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tono para este servicio',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: MusicalKey.allSharpNames
                      .indexOf(MusicalKey.isValid(temp) ? temp : 'C')
                      .clamp(0, 11),
                ),
                onSelectedItemChanged: (i) =>
                    temp = MusicalKey.allSharpNames[i],
                children: [
                  for (final k in MusicalKey.allSharpNames)
                    Center(
                      child: Text(k, style: const TextStyle(fontSize: 24)),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  onPressed: () async {
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
                CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () async {
                    await ref.read(setlistsRepositoryProvider).updateItem(
                          groupId: groupId,
                          setlistId: setlistId,
                          itemId: itemId,
                          overrideKey: temp,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
