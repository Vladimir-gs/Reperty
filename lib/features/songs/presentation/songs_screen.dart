import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/musical_key.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../data/songs_repository.dart';

/// Cantos del grupo: buscar, agregar, ver tono original.
class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(currentGroupProvider);
    if (group == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LargeTitle(title: 'Cantos'),
                Expanded(
                  child: EmptyState(
                    icon: CupertinoIcons.music_note,
                    title: 'Selecciona un grupo para ver su repertorio.',
                    action: PrimaryButton(
                      label: 'Ver grupos',
                      onPressed: () => context.go('/groups'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final songs = ref.watch(groupSongsProvider(group.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, ref, group.id),
        child: const Icon(CupertinoIcons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LargeTitle(title: 'Cantos', subtitle: group.name),
              AppleSearchField(
                placeholder: 'Buscar canto…',
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
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
                        icon: CupertinoIcons.music_note,
                        title:
                            'Sin cantos.\nAgrega el primero del repertorio.',
                      );
                    }
                    return SingleChildScrollView(
                      child: GroupedSection(
                        children: [
                        for (final s in filtered)
                          AppleRow(
                            title: s.title,
                            subtitle: s.artist.isEmpty
                                ? 'Tono original'
                                : s.artist,
                            trailing: KeyBadge(musicalKey: s.originalKey),
                            showChevron: true,
                            onTap: () =>
                                context.go('/songs/${s.songId}'),
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

  void _showAdd(BuildContext context, WidgetRef ref, String groupId) {
    final title = TextEditingController();
    final artist = TextEditingController();
    final form = GlobalKey<FormState>();
    var key = 'C';
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: const Text('Nuevo canto'),
          content: Form(
            key: form,
            child: Column(
              children: [
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: title,
                  placeholder: 'Título',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: artist,
                  placeholder: 'Artista (opcional)',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _pickKey(
                    ctx,
                    (v) => setDialogState(() => key = v),
                  ),
                  child: Text('Tono original: $key'),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                if (!form.currentState!.validate() ||
                    title.text.trim().isEmpty) {
                  return;
                }
                final uid = ref.read(authStateProvider).valueOrNull?.uid;
                if (uid == null) return;
                await ref.read(songsRepositoryProvider).addSongToGroup(
                      groupId: groupId,
                      title: title.text,
                      artist: artist.text,
                      originalKey: key,
                      addedBy: uid,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickKey(BuildContext context, ValueChanged<String> onPick) {
    var temp = 'C';
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
                onSelectedItemChanged: (i) =>
                    temp = MusicalKey.allSharpNames[i],
                children: [
                  for (final k in MusicalKey.allSharpNames) Text(k),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
