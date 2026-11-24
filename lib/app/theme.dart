import 'package:flutter/material.dart';

abstract final class MihrabTokens {
  static const background = Color(0xFF071F1B);
  static const emerald = Color(0xFF103D32);
  static const gold = Color(0xFFD9BD85);
  static const cream = Color(0xFFF3EFE4);
  static const space = 20.0;
  static const radius = 24.0;
}

abstract final class MihrabTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: MihrabTokens.emerald, brightness: brightness).copyWith(
      primary: dark ? MihrabTokens.gold : MihrabTokens.emerald,
      surface: dark ? MihrabTokens.background : MihrabTokens.cream,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface, elevation: 0, centerTitle: false),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.symmetric(vertical: 4)),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: scheme.surface));
  }
}
