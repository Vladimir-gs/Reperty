import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/musical_key.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../groups/data/groups_repository.dart';
import '../../songs/data/songs_repository.dart';
import '../data/setlists_repository.dart';
import '../domain/setlist_models.dart';
import 'setlists_screen.dart' show MiniCalendar;

/// Detalle del setlist: orden táctil, vocalista y tono por servicio.
/// Solo managers editan; los setlists cerrados son solo lectura.
class SetlistDetailScreen extends ConsumerWidget {
  const SetlistDetailScreen({super.key, required this.setlistId});

  final String setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(currentGroupProvider);
    if (group == null) {
      return const Scaffold(body: LoadingView());
    }
    final setlistAsync = ref.watch(
      setlistProvider((groupId: group.id, setlistId: setlistId)),
    );
    final items = ref.watch(
      setlistItemsProvider((groupId: group.id, setlistId: setlistId)),
    );
    final isManager = ref.watch(amManagerProvider(group.id));
    final setlist = setlistAsync.valueOrNull;
    final closed = setlist?.isClosed ?? false;
    final canEdit = isManager && !closed;
    return Scaffold(
      appBar: AppBar(
        title: Text(setlist?.name ?? 'Setlist'),
        actions: [
          if (isManager)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: setlist == null
                  ? null
                  : () =>
                      _showEditSetlist(context, ref, group.id, setlist),
              child: const Icon(CupertinoIcons.pencil, size: 22),
            ),
          if (canEdit)
            CupertinoButton(
              padding: const EdgeInsets.only(right: 12),
              onPressed: () =>
                  _showAddSong(context, ref, group.id, setlistId),
              child: const Icon(CupertinoIcons.add),
            ),
        ],
      ),
      body: setlistAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) {
          if (s == null) {
            return const EmptyState(
              icon: CupertinoIcons.list_bullet,
              title: 'Setlist no encontrado.',
            );
          }
          return items.when(
            loading: () => const LoadingView(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _Body(
              list: list,
              closed: closed,
              canEdit: canEdit,
              isManager: isManager,
              onAdd: () =>
                  _showAddSong(context, ref, group.id, setlistId),
              onEditItem: (item) => _showEditItem(
                context,
                ref,
                group.id,
                setlistId,
                item.id,
                item.overrideKey,
              ),
              onReorder: (ids) =>
                  ref.read(setlistsRepositoryProvider).reorder(
                        groupId: group.id,
                        setlistId: setlistId,
                        orderedItemIds: ids,
                      ),
              onDelete: () =>
                  _confirmDelete(context, ref, group.id, setlistId),
            ),
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
                  options: [
                    for (final s in songs) '${s.title} · ${s.originalKey}',
                  ],
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

  void _showEditSetlist(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    Setlist setlist,
  ) {
    final name = TextEditingController(text: setlist.name);
    var day = setlist.date ?? DateTime.now();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Editar setlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    hintText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 340,
                  width: 300,
                  child: MiniCalendar(
                    focusedDay: day,
                    selectedDay: day,
                    onSelect: (d) => setDialogState(() => day = d),
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
                if (name.text.trim().isEmpty) return;
                try {
                  await ref.read(setlistsRepositoryProvider).updateSetlist(
                        groupId: groupId,
                        setlistId: setlist.id,
                        name: name.text,
                        date: day,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                } on Exception catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo guardar: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String setlistId,
  ) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar setlist'),
        content: const Text('Se eliminará con todas sus canciones.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              try {
                await ref
                    .read(setlistsRepositoryProvider)
                    .deleteSetlist(groupId, setlistId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.pop();
              } on Exception catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo eliminar: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Contenido del setlist: solo lectura si está cerrado o no soy manager.
class _Body extends StatelessWidget {
  const _Body({
    required this.list,
    required this.closed,
    required this.canEdit,
    required this.isManager,
    required this.onAdd,
    required this.onEditItem,
    required this.onReorder,
    required this.onDelete,
  });

  final List<SetlistSong> list;
  final bool closed;
  final bool canEdit;
  final bool isManager;
  final VoidCallback onAdd;
  final ValueChanged<SetlistSong> onEditItem;
  final ValueChanged<List<String>> onReorder;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return EmptyState(
        icon: CupertinoIcons.list_bullet,
        title: 'Setlist vacío.\nAgrega cantos del repertorio.',
        action: canEdit
            ? PrimaryButton(label: 'Agregar canto', onPressed: onAdd)
            : null,
      );
    }
    return Column(
      children: [
        if (closed)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.archivebox,
                  size: 20,
                  color: AppTheme.iosGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Setlist cerrado · solo lectura',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (canEdit)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Mantén y arrastra para ordenar · toca para ajustar el tono',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          const SizedBox(height: 12),
        Expanded(
          child: canEdit
              ? ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final ids = list.map((e) => e.id).toList();
                    final moved = ids.removeAt(oldIndex);
                    ids.insert(newIndex, moved);
                    onReorder(ids);
                  },
                  itemBuilder: (context, i) => _ItemCard(
                    key: ValueKey(list[i].id),
                    item: list[i],
                    index: i,
                    onTap: onEditItem,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _ItemCard(
                    key: ValueKey(list[i].id),
                    item: list[i],
                    index: i,
                    onTap: (_) {},
                  ),
                ),
        ),
        if (isManager && !closed)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CupertinoButton(
              onPressed: onDelete,
              child: const Text(
                'Eliminar setlist',
                style: TextStyle(color: CupertinoColors.systemRed),
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  final SetlistSong item;
  final int index;
  final ValueChanged<SetlistSong> onTap;

  @override
  Widget build(BuildContext context) {
    final key = item.effectiveKey ?? '—';
    final isOverride = item.overrideKey != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: AppleRow(
        leading: Text(
          (index + 1).toString().padLeft(2, '0'),
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
        onTap: () => onTap(item),
      ),
    );
  }
}
