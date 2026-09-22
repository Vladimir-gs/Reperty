import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../../setlists/data/setlists_repository.dart';
import '../../songs/data/songs_repository.dart';

/// Inicio: saludo grande, grupo actual, próximo setlist y conteos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final group = ref.watch(selectedGroupProvider);
    final myGroups = ref.watch(myGroupsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          children: [
            profile.when(
              loading: () => const LoadingView(),
              error: (e, _) => Text('Error: $e'),
              data: (user) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.iosGrey,
                                  ),
                        ),
                        Text(
                          user == null
                              ? 'Hola'
                              : firstName(user.name),
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showSwitchGroup(context, ref),
                    child: const Icon(CupertinoIcons.arrow_2_circlepath),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            myGroups.when(
              loading: () => const LoadingView(message: 'Cargando grupos…'),
              error: (e, _) => Text('Error: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: CupertinoIcons.group,
                    title:
                        'Aún no tienes grupo.\nCrea uno o únete con un código.',
                    action: PrimaryButton(
                      label: 'Ir a grupos',
                      onPressed: () => context.go('/groups'),
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
                    Text(
                      'Código ${current.code}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SectionTitle(title: 'Próximo setlist'),
                    _NextSetlist(groupId: current.id),
                    const SectionTitle(title: 'Resumen'),
                    _CountsRow(groupId: current.id),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Ver setlists',
                      onPressed: () => context.go('/setlists'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Hola' : parts.first;
  }

  void _showSwitchGroup(BuildContext context, WidgetRef ref) {
    final groups = ref.read(myGroupsProvider).valueOrNull ?? [];
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Cambiar de grupo'),
        actions: [
          for (final g in groups)
            CupertinoActionSheetAction(
              onPressed: () {
                ref.read(selectedGroupProvider.notifier).state = g;
                Navigator.pop(ctx);
              },
              child: Text(g.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
}

class _NextSetlist extends ConsumerWidget {
  const _NextSetlist({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setlists = ref.watch(setlistsProvider(groupId));
    return setlists.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: const LoadingView(),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (list) {
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: const EmptyState(
              icon: CupertinoIcons.list_bullet,
              title: 'Aún no hay setlists.',
            ),
          );
        }
        final next = list.first;
        return GroupedSection(
          children: [
            AppleRow(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.iosBlue.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.music_note_list,
                  color: AppTheme.iosBlue,
                ),
              ),
              title: next.name,
              subtitle: next.date != null
                  ? '${next.date!.day}/${next.date!.month}/${next.date!.year}'
                  : (next.description.isEmpty ? 'Sin fecha' : next.description),
              showChevron: true,
              onTap: () => context.go('/setlists/${next.id}'),
            ),
          ],
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
          child: _StatCard(
            value: songs.valueOrNull?.length.toString() ?? '—',
            label: 'Cantos',
            icon: CupertinoIcons.music_note,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: members.valueOrNull?.length.toString() ?? '—',
            label: 'Miembros',
            icon: CupertinoIcons.group,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppTheme.iosBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 30,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
