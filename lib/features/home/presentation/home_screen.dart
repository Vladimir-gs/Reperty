import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../../setlists/data/setlists_repository.dart';
import '../../setlists/domain/setlist_models.dart';
import '../../songs/data/songs_repository.dart';

/// Inicio: saludo grande, grupo actual, próximo setlist y conteos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final group = ref.watch(currentGroupProvider);
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                          user == null ? 'Hola' : firstName(user.name),
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: CupertinoColors.systemGrey5,
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? Text(
                              (user == null || user.name.isEmpty)
                                  ? '?'
                                  : user.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 20),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                final current = group;
                if (current == null) {
                  // Varios grupos y ninguno elegido: selector inicial.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LargeTitle(
                        title: 'Elige un grupo',
                        subtitle: '¿Con cuál quieres trabajar hoy?',
                      ),
                      GroupedSection(
                        children: [
                          for (final g in list)
                            AppleRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient:
                                      AppTheme.brandGradientStrong,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.music_note_2,
                                  color: CupertinoColors.white,
                                ),
                              ),
                              title: g.name,
                              subtitle: 'Código ${g.code}',
                              showChevron: true,
                              onTap: () => ref
                                  .read(selectedGroupProvider.notifier)
                                  .state = g,
                            ),
                        ],
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GroupedSection(
                      children: [
                        AppleRow(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppTheme.brandGradientStrong,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              CupertinoIcons.music_note_2,
                              color: CupertinoColors.white,
                            ),
                          ),
                          title: current.name,
                          subtitle:
                              'Código ${current.code} · toca para cambiar',
                          showChevron: true,
                          onTap: () => _showSwitchGroup(context, ref),
                        ),
                      ],
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
        final upcoming = list.where((s) => !s.isClosed).toList()
          ..sort((a, b) {
            if (a.date == null && b.date == null) return 0;
            if (a.date == null) return 1;
            if (b.date == null) return -1;
            return a.date!.compareTo(b.date!);
          });
        if (upcoming.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: const EmptyState(
              icon: CupertinoIcons.check_mark_circled,
              title: 'Sin setlists próximos.',
            ),
          );
        }
        final next = upcoming.first;
        return HeroCard(
          onTap: () => context.go('/setlists/${next.id}'),
          children: [
            const Text(
              'PRÓXIMO SETLIST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              next.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              next.date != null
                  ? '${next.date!.day}/${next.date!.month}/${next.date!.year}'
                  : (next.description.isEmpty
                      ? 'Sin fecha'
                      : next.description),
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text(
                  'Abrir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.white,
                ),
              ],
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
