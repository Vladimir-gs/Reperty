import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';

/// Perfil: cuenta, mis grupos y cerrar sesión.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final myGroups = ref.watch(myGroupsProvider);
    final current = ref.watch(currentGroupProvider);
    return Scaffold(
      body: SafeArea(
        child: profile.when(
          loading: () => const LoadingView(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Sin sesión.'));
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const LargeTitle(title: 'Perfil'),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: CupertinoColors.systemGrey5,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.name.isEmpty
                                    ? '?'
                                    : user.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 36),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style:
                            Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SectionTitle(title: 'Cuenta'),
                GroupedSection(
                  children: [
                    AppleRow(
                      title: 'Nombre',
                      trailing: Text(
                        user.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    AppleRow(
                      title: 'Email',
                      trailing: Text(
                        user.email.isEmpty ? '—' : user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SectionTitle(title: 'Mis grupos'),
                myGroups.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) {
                    if (list.isEmpty) {
                      return Text(
                        'Aún no perteneces a ningún grupo.',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    return GroupedSection(
                      children: [
                        for (final g in list)
                          AppleRow(
                            title: g.name,
                            subtitle: 'Código ${g.code}',
                            trailing: current?.id == g.id
                                ? const Icon(
                                    CupertinoIcons.check_mark,
                                    color: CupertinoColors.activeBlue,
                                  )
                                : null,
                            onTap: () => ref
                                .read(selectedGroupProvider.notifier)
                                .state = g,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                GroupedSection(
                  children: [
                    AppleRow(
                      title: 'Cerrar sesión',
                      onTap: () =>
                          ref.read(authRepositoryProvider).signOut(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Reperty · v0.1.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
