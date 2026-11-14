import 'package:flutter/material.dart';

import '../features/scan/scan_models.dart';

abstract final class UsisaTheme {
  static const cream = Color(0xFFEEE5D4);
  static const forest = Color(0xFF1D4A35);
  static const coral = Color(0xFFF2452E);
  static const contrastCoral = Color(0xFFB92E22);
  static ThemeData get light => _theme();

  static ThemeData _theme() {
    const background = cream;
    const surface = Color(0xFFF8F2E7);
    const text = forest;
    const muted = Color(0xFF49624F);
    const primary = forest;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: forest,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: cream,
          secondary: forest,
          onSecondary: cream,
          tertiary: coral,
          onTertiary: forest,
          error: contrastCoral,
          onError: cream,
          surface: surface,
          onSurface: text,
          onSurfaceVariant: muted,
          outline: forest.withValues(alpha: .52),
          outlineVariant: forest.withValues(alpha: .18),
          surfaceContainerLowest: background,
          surfaceContainerLow: surface,
          surfaceContainer: const Color(0xFFF2EBDD),
          surfaceContainerHigh: const Color(0xFFE7DECD),
          surfaceContainerHighest: const Color(0xFFDED4C3),
          primaryContainer: const Color(0xFFDDE5D7),
          onPrimaryContainer: forest,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 30,
          height: 1.15,
          letterSpacing: -.35,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.2,
          letterSpacing: -.2,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(18),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          foregroundColor: cream,
          backgroundColor: const Color(0xFF0B6048),
          disabledForegroundColor: cream.withValues(alpha: .72),
          disabledBackgroundColor: const Color(0xFF9DB5A8),
          elevation: 3,
          shadowColor: forest.withValues(alpha: .2),
          side: BorderSide(
            color: const Color(0xFF2C9A76).withValues(alpha: .76),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: surface,
          foregroundColor: forest,
          elevation: 1,
          shadowColor: forest.withValues(alpha: .1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          side: BorderSide(color: forest.withValues(alpha: .36), width: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: forest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.white,
        elevation: 3,
        shadowColor: forest.withValues(alpha: .14),
        margin: EdgeInsets.zero,
        shape: shape,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: forest.withValues(alpha: .1),
      ),
      chipTheme: base.chipTheme.copyWith(side: BorderSide.none),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static (Color, Color, IconData) risk(BuildContext context, RiskLevel risk) {
    return switch (risk) {
      RiskLevel.high => (contrastCoral, cream, Icons.gpp_bad_outlined),
      RiskLevel.caution => (
        forest,
        const Color(0xFFE7DECD),
        Icons.info_outline_rounded,
      ),
      RiskLevel.low => (
        forest,
        const Color(0xFFDDE5D7),
        Icons.fact_check_outlined,
      ),
    };
  }
}
