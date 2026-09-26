import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../groups/data/groups_repository.dart';
import '../data/setlists_repository.dart';
import '../domain/setlist_models.dart';

class SetlistsScreen extends ConsumerStatefulWidget {
  const SetlistsScreen({super.key});

  @override
  ConsumerState<SetlistsScreen> createState() => _SetlistsScreenState();
}

class _SetlistsScreenState extends ConsumerState<SetlistsScreen> {
  /// 0 = Próximos, 1 = Historial.
  int _tab = 0;

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
    final isManager = ref.watch(amManagerProvider(group.id));
    return Scaffold(
      floatingActionButton: isManager
          ? FloatingActionButton(
              onPressed: () => _showCreate(context, ref, group.id),
              child: const Icon(CupertinoIcons.add),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LargeTitle(title: 'Setlists', subtitle: group.name),
              CupertinoSegmentedControl<int>(
                groupValue: _tab,
                padding: const EdgeInsets.all(2),
                borderColor: AppTheme.iosGrey.withAlpha(40),
                selectedColor: AppTheme.brandBlue,
                unselectedColor: Colors.transparent,
                pressedColor: AppTheme.brandBlue.withAlpha(25),
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Próximos'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Historial'),
                  ),
                },
                onValueChanged: (v) => setState(() => _tab = v),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: setlists.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (list) {
                    // Ordenar por fecha ascendente; sin fecha al final.
                    final sorted = [...list]..sort((a, b) {
                      if (a.date == null && b.date == null) return 0;
                      if (a.date == null) return 1;
                      if (b.date == null) return -1;
                      return a.date!.compareTo(b.date!);
                    });
                    final visible = _tab == 0
                        ? sorted.where((s) => !s.isClosed).toList()
                        : sorted.where((s) => s.isClosed).toList();
                    if (visible.isEmpty) {
                      return EmptyState(
                        icon: CupertinoIcons.list_bullet,
                        title: _tab == 0
                            ? 'Sin setlists próximos.\nCrea el primero.'
                            : 'Aún no hay historial.',
                      );
                    }
                    return SingleChildScrollView(
                      child: GroupedSection(
                        children: [
                          for (final s in visible)
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
                                      s.date != null ? '${s.date!.day}' : '♪',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                title: s.name,
                                subtitle: _subtitle(s),
                                showChevron: true,
                                onTap: () =>
                                    context.go('/setlists/${s.id}'),
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

  String _subtitle(Setlist s) {
    if (s.date == null) return 'Sin fecha';
    return '${s.date!.day}/${s.date!.month}/${s.date!.year}';
  }

  void _showCreate(BuildContext context, WidgetRef ref, String groupId) {
    final name = TextEditingController();
    var day = DateTime.now();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Nuevo setlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    hintText: 'Domingo 21 Septiembre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 340,
                  width: 300,
                  child: _MiniCalendar(
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
                final uid =
                    ref.read(authStateProvider).valueOrNull?.uid ?? '';
                try {
                  await ref.read(setlistsRepositoryProvider).createSetlist(
                        groupId: groupId,
                        name: name.text,
                        date: day,
                        createdBy: uid,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                } on Exception catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo crear: $e')),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minicalendario para elegir el día del setlist.
class MiniCalendar extends StatelessWidget {
  const MiniCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return _MiniCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      onSelect: onSelect,
    );
  }
}

class _MiniCalendar extends StatefulWidget {
  const _MiniCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<_MiniCalendar> {
  late DateTime _focused;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar<void>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 730)),
      focusedDay: _focused,
      selectedDayPredicate: (d) => isSameDay(d, widget.selectedDay),
      onDaySelected: (selected, focused) {
        setState(() => _focused = focused);
        widget.onSelect(DateTime(selected.year, selected.month, selected.day));
      },
      onPageChanged: (d) => setState(() => _focused = d),
      calendarStyle: const CalendarStyle(
        selectedDecoration: BoxDecoration(
          gradient: AppTheme.brandGradientStrong,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: CupertinoColors.systemGrey4,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: Icon(CupertinoIcons.chevron_left, size: 18),
        rightChevronIcon: Icon(CupertinoIcons.chevron_right, size: 18),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 12, color: AppTheme.iosGrey),
        weekendStyle: TextStyle(fontSize: 12, color: AppTheme.iosGrey),
      ),
    );
  }
}
