import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/theme/app_theme.dart';
import 'common_widgets.dart';

/// Previews visibles en el IDE sin compilar la app completa.
/// Android Studio / VS Code con plugin Flutter reciente: panel
/// "Flutter Widget Preview". Alternativa: hot reload (r).

@Preview(name: 'KeyBadge · tono', group: 'Reperty')
Widget keyBadgePreview() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(
      body: Center(child: KeyBadge(musicalKey: 'A')),
    ),
  );
}

@Preview(name: 'KeyBadge · grande (servicio)', group: 'Reperty')
Widget keyBadgeLargePreview() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(
      body: Center(child: KeyBadge(musicalKey: 'F#', large: true)),
    ),
  );
}

@Preview(name: 'EmptyState', group: 'Reperty')
Widget emptyStatePreview() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: EmptyState(
        icon: CupertinoIcons.music_note,
        title: 'Sin cantos.\nAgrega el primero del repertorio.',
        action: PrimaryButton(label: 'Agregar', onPressed: () {}),
      ),
    ),
  );
}

@Preview(name: 'Fila canto (setlist)', group: 'Reperty')
Widget setlistRowPreview() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LargeTitle(title: 'Domingo 21'),
            SizedBox(height: 8),
            AppleRow(
              leading: Text('01'),
              title: 'Hosanna',
              subtitle: 'María',
              trailing: KeyBadge(musicalKey: 'A'),
            ),
            AppleRow(
              leading: Text('02'),
              title: 'Tu Fidelidad',
              subtitle: 'Vladimir',
              trailing: KeyBadge(musicalKey: 'G'),
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Sección agrupada', group: 'Reperty')
Widget groupedSectionPreview() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LargeTitle(title: 'Cantos', subtitle: 'Ministerio de Alabanza'),
            GroupedSection(
              children: [
                AppleRow(
                  title: 'Hosanna',
                  subtitle: 'Hillsong',
                  trailing: KeyBadge(musicalKey: 'E'),
                ),
                AppleRow(
                  title: 'Grande es Tu Fidelidad',
                  subtitle: 'Tono original',
                  trailing: KeyBadge(musicalKey: 'D'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
