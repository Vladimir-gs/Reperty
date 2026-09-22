import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../data/setlists_repository.dart';

class SetlistsScreen extends ConsumerWidget {
  const SetlistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(selectedGroupProvider);
    if (group == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LargeTitle(title: 'Setlists'),
                Expanded(
                  child: EmptyState(
                    icon: CupertinoIcons.list_bullet,
                    title: 'Selecciona un grupo para ver sus setlists.',
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
    final setlists = ref.watch(setlistsProvider(group.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreate(context, ref, group.id),
        child: const Icon(CupertinoIcons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LargeTitle(title: 'Setlists', subtitle: group.name),
              Expanded(
                child: setlists.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (list) {
                    if (list.isEmpty) {
                      return const EmptyState(
                        icon: CupertinoIcons.list_bullet,
                        title:
                            'Sin setlists.\nCrea el primero (ej. Domingo 21).',
                      );
                    }
                    return GroupedSection(
                      children: [
                        for (final s in list)
                          AppleRow(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  s.date != null
                                      ? '${s.date!.day}'
                                      : '♪',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            title: s.name,
                            subtitle: s.date != null
                                ? '${s.date!.day}/${s.date!.month}/${s.date!.year}'
                                : (s.description.isEmpty
                                    ? 'Sin fecha'
                                    : s.description),
                            showChevron: true,
                            onTap: () => context.go('/setlists/${s.id}'),
                          ),
                      ],
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

  void _showCreate(BuildContext context, WidgetRef ref, String groupId) {
    final name = TextEditingController();
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Nuevo setlist'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: name,
              placeholder: 'Domingo 21 Septiembre',
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
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
              if (name.text.trim().isEmpty) return;
              final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
              await ref.read(setlistsRepositoryProvider).createSetlist(
                    groupId: groupId,
                    name: name.text,
                    date: DateTime.now(),
                    createdBy: uid,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
