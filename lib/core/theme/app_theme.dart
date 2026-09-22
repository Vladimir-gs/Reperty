import 'package:flutter/material.dart';

/// Tema Material 3, minimalista y legible para escenario/ensayo.
abstract final class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFF1B4D3E); // verde profundo musical
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      textTheme: const TextTheme(
        // Tono grande y legible para mostrar en servicio.
        displaySmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }

  static ThemeData dark() {
    const seed = Color(0xFF1B4D3E);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
