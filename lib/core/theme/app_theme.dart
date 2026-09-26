import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Sistema de diseño estilo Apple HIG.
///
/// - Fondo agrupado (systemGroupedBackground)
/// - Títulos grandes (Large Title 34)
/// - Listas agrupadas blancas con radio 14, sin sombras
/// - Acento iOS blue, grises del sistema
/// - Espaciado generoso: pantallas 20, secciones 32
abstract final class AppTheme {
  // Paleta iOS.
  static const iosBlue = Color(0xFF007AFF);
  static const iosBlueDark = Color(0xFF0A84FF);
  static const iosGrey = Color(0xFF8E8E93);
  static const groupedLight = Color(0xFFF2F2F7);
  static const cardDark = Color(0xFF1C1C1E);

  /// Identidad de marca: azul característico en degradado.
  /// Inspirado en referencias: botón degradado + glow azul sobre oscuro.
  static const brandDeep = Color(0xFF0A2540);
  static const brandBlue = Color(0xFF2E7CF6);
  static const brandLight = Color(0xFF7FB2FF);
  static const brandNight = Color(0xFF050810);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandLight, brandBlue],
  );

  static const brandGradientStrong = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, Color(0xFF1D4ED8)],
  );

  static const nightGlow = RadialGradient(
    center: Alignment(0, -0.4),
    radius: 0.9,
    colors: [Color(0xFF1D4ED8), Color(0x00000000)],
  );

  static const double screenPadding = 20;
  static const double sectionGap = 32;
  static const double cardRadius = 14;

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: iosBlue,
      onPrimary: CupertinoColors.white,
      surface: CupertinoColors.white,
      surfaceContainerHighest: groupedLight,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: groupedLight,
      cardColor: CupertinoColors.white,
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: groupedLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
        iconTheme: IconThemeData(color: iosBlue),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: CupertinoColors.black,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.black,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
        bodyLarge: TextStyle(fontSize: 17, color: CupertinoColors.black),
        bodyMedium: TextStyle(fontSize: 15, color: CupertinoColors.black),
        bodySmall: TextStyle(fontSize: 13, color: iosGrey),
      ),
      dividerColor: const Color(0xFFC6C6C8),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CupertinoColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: iosBlueDark,
      onPrimary: CupertinoColors.white,
      surface: cardDark,
      surfaceContainerHighest: CupertinoColors.black,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: CupertinoColors.black,
      cardColor: cardDark,
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CupertinoColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
        iconTheme: IconThemeData(color: iosBlueDark),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: CupertinoColors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
        bodyLarge: TextStyle(fontSize: 17, color: CupertinoColors.white),
        bodyMedium: TextStyle(fontSize: 15, color: CupertinoColors.white),
        bodySmall: TextStyle(fontSize: 13, color: iosGrey),
      ),
      dividerColor: const Color(0xFF38383A),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
    );
  }
}
