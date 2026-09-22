import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'common_widgets.dart';

/// Previews visibles en el IDE sin compilar la app completaa.
/// Android Studio / VS Code con plugin Flutter reciente: panel
/// "Flutter Widget Preview". Alternativa siempre disponible: hot reload (r).

@Preview(name: 'KeyBadge · tono', group: 'Reperty')
Widget keyBadgePreview() {
  return const MaterialApp(
    home: Scaffold(body: Center(child: KeyBadge(musicalKey: 'A'))),
  );
}

@Preview(name: 'KeyBadge · grande (servicio)', group: 'Reperty')
Widget keyBadgeLargePreview() {
  return const MaterialApp(
    home: Scaffold(body: Center(child: KeyBadge(musicalKey: 'F#', large: true))),
  );
}

@Preview(name: 'EmptyState', group: 'Reperty')
Widget emptyStatePreview() {
  return const MaterialApp(
    home: Scaffold(
      body: EmptyState(
        title: 'Sin canciones.\nAgrega la primera del repertorio.',
        action: FilledButton(onPressed: null, child: Text('Agregar')),
      ),
    ),
  );
}

@Preview(name: 'Fila canción (setlist)', group: 'Reperty')
Widget setlistRowPreview() {
  return MaterialApp(
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Text('01'),
              title: Text('Hosanna'),
              subtitle: Text('María'),
              trailing: KeyBadge(musicalKey: 'A'),
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Text('02'),
              title: Text('Tu Fidelidad'),
              subtitle: Text('Vladimir'),
              trailing: KeyBadge(musicalKey: 'G'),
            ),
          ),
        ],
      ),
    ),
  );
}
