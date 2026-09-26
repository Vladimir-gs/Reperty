import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/musical_key.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../groups/data/groups_repository.dart';
import '../data/songs_repository.dart';

/// Detalle del canto: tono original grande + tonos por vocalista.
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(currentGroupProvider);
    if (group == null) {
      return const Scaffold(body: LoadingView());
    }
    final songs = ref.watch(groupSongsProvider(group.id));
    final keys = ref.watch(
      vocalistKeysProvider((groupId: group.id, songId: songId)),
    );
    final members = ref.watch(groupMembersProvider(group.id));

    return Scaffold(
      appBar: AppBar(),
      body: songs.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final song = list.where((s) => s.songId == songId).firstOrNull;
          if (song == null) {
            return const EmptyState(
              icon: CupertinoIcons.music_note,
              title: 'Canto no encontrado.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                song.title,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              if (song.artist.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'TONO ORIGINAL',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    KeyBadge(musicalKey: song.originalKey, large: true),
                  ],
                ),
              ),
              const SectionTitle(title: 'Tonos por vocalista'),
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
                        return const EmptyState(
                          icon: CupertinoIcons.person_2,
                          title: 'Sin miembros en el grupo.',
                        );
                      }
                      return GroupedSection(
                        children: [
                          for (final m in shown)
                            AppleRow(
                              leading: CircleAvatar(
                                backgroundColor:
                                    CupertinoColors.systemGrey5,
                                backgroundImage: m.photoUrl != null
                                    ? NetworkImage(m.photoUrl!)
                                    : null,
                                child: m.photoUrl == null
                                    ? Text(
                                        ((m.displayName ?? '?').isEmpty
                                                ? '?'
                                                : (m.displayName ?? '?')[0])
                                            .toUpperCase(),
                                      )
                                    : null,
                              ),
                              title: m.displayName ?? m.userId,
                              trailing: KeyBadge(
                                musicalKey: byUser[m.userId]?.key ?? '—',
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
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Toca un vocalista para ajustar su tono.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
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
    var temp = MusicalKey.isValid(current)
        ? MusicalKey.parse(current).sharpName
        : 'C';
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: Theme.of(ctx).cardColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                CupertinoButton(
                  onPressed: () async {
                    await ref.read(songsRepositoryProvider).setVocalistKey(
                          groupId: groupId,
                          songId: songId,
                          userId: userId,
                          key: temp,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: MusicalKey.allSharpNames.indexOf(temp),
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
          ],
        ),
      ),
    );
  }
}
