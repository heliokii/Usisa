import 'package:flutter/material.dart';

import '../features/scan/scan_models.dart';

abstract final class UsisaTheme {
  static ThemeData get light => _theme(false);
  static ThemeData get dark => _theme(true);
  static ThemeData _theme(bool dark) {
    final background = Color(dark ? 0xFF0E191E : 0xFFF5F8FA);
    final surface = Color(dark ? 0xFF15262D : 0xFFFFFFFF);
    final text = Color(dark ? 0xFFEFF7F8 : 0xFF162B33);
    final secondary = Color(dark ? 0xFFB7CDD2 : 0xFF52666D);
    final primary = Color(dark ? 0xFF76D8CD : 0xFF0B6B65);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Color(dark ? 0xFF063C37 : 0xFFFFFFFF),
          surface: surface,
          onSurface: text,
          onSurfaceVariant: secondary,
          outline: Color(dark ? 0xFF78909A : 0xFF6C818A),
          outlineVariant: Color(dark ? 0xFF3A545E : 0xFFD7E1E5),
          surfaceContainerLowest: background,
          surfaceContainerLow: surface,
          surfaceContainer: surface,
          surfaceContainerHigh: surface,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 30,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          height: 1.22,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: secondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: shape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: shape,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: .12),
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: .12),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: scheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  static (Color, Color, IconData) risk(BuildContext context, RiskLevel risk) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (risk) {
      RiskLevel.high => (
        Color(dark ? 0xFFFFA8AF : 0xFFA52A36),
        Color(dark ? 0xFF3E2029 : 0xFFFCEDEF),
        Icons.warning_amber_rounded,
      ),
      RiskLevel.caution => (
        Color(dark ? 0xFFF2CE79 : 0xFF805100),
        Color(dark ? 0xFF382E18 : 0xFFFFF4D9),
        Icons.info_outline_rounded,
      ),
      RiskLevel.low => (
        Color(dark ? 0xFF90DEBE : 0xFF126354),
        Color(dark ? 0xFF16372F : 0xFFE4F5EE),
        Icons.search_rounded,
      ),
    };
  }
}
