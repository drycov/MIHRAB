import 'package:material_ui/material_ui.dart';

abstract final class MihrabTokens {
  // Core palette — deep mosque green, warm gold, parchment
  static const background = Color(0xFF071F1B);
  static const emerald = Color(0xFF0E342B);
  static const emeraldDeep = Color(0xFF062018);
  static const emeraldSoft = Color(0xFF164A3C);
  static const gold = Color(0xFFD4B06A);
  static const goldSoft = Color(0xFFE8D5A3);
  static const cream = Color(0xFFF6F1E6);
  static const creamMuted = Color(0xFFE8E0D0);
  static const ink = Color(0xFF1A2E28);
  static const muted = Color(0xFF6B7F78);

  static const paper = Colors.white;
  static const transparent = Colors.transparent;
  static const space = 20.0;
  static const spaceSm = 12.0;
  static const spaceLg = 28.0;
  static const radius = 20.0;
  static const radiusSm = 12.0;
  static const radiusLg = 28.0;

  static const letterTitle = 3.0;
  static const letterLabel = 1.2;
}

abstract final class MihrabTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: MihrabTokens.emerald,
      brightness: brightness,
    ).copyWith(
      primary: dark ? MihrabTokens.gold : MihrabTokens.emerald,
      onPrimary: dark ? MihrabTokens.background : MihrabTokens.cream,
      secondary: MihrabTokens.gold,
      onSecondary: MihrabTokens.background,
      surface: dark ? MihrabTokens.background : MihrabTokens.cream,
      onSurface: dark ? MihrabTokens.cream : MihrabTokens.ink,
      surfaceContainerHighest:
          dark ? MihrabTokens.emerald : MihrabTokens.creamMuted,
      outline: dark ? MihrabTokens.emeraldSoft : MihrabTokens.creamMuted,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outline.withValues(alpha: 0.35),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        actionsIconTheme: IconThemeData(color: scheme.primary),
        iconTheme: IconThemeData(color: scheme.primary),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: MihrabTokens.letterTitle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MihrabTokens.radius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: MihrabTokens.space,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MihrabTokens.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color:
            dark
                ? MihrabTokens.emerald.withValues(alpha: 0.55)
                : MihrabTokens.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MihrabTokens.radius),
          side: BorderSide(
            color:
                dark
                    ? MihrabTokens.gold.withValues(alpha: 0.12)
                    : MihrabTokens.emerald.withValues(alpha: 0.08),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor:
            dark
                ? MihrabTokens.gold.withValues(alpha: 0.18)
                : MihrabTokens.emerald.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.3,
            color:
                selected
                    ? (dark ? MihrabTokens.gold : MihrabTokens.emerald)
                    : scheme.onSurface.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color:
                selected
                    ? (dark ? MihrabTokens.gold : MihrabTokens.emerald)
                    : scheme.onSurface.withValues(alpha: 0.55),
          );
        }),
        height: 68,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MihrabTokens.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return MihrabTokens.gold;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return MihrabTokens.emeraldSoft;
          }
          return null;
        }),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
      ),
    );
  }
}
