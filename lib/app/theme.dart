import 'package:flutter/material.dart';

import 'motion.dart';

/// Colour tokens from DESIGN.md. Contrast ratios are listed there.
abstract final class UsisaColors {
  static const primary = Color(0xFF4A44C9);
  static const background = Color(0xFFEEF0FF);
  static const surface = Colors.white;
  static const ink = Color(0xFF1F1D4D);
  static const inkMuted = Color(0xFF5B5A7A);
  static const yellow = Color(0xFFFFD66B);
  static const lilac = Color(0xFFC9C7FF);
  static const mint = Color(0xFFA8E6D4);
  static const coral = Color(0xFFFFC2B8);
  static const coralDot = Color(0xFFFF8A8A);
  static const orange = Color(0xFFFF8A4C);
  static const hairline = Color(0xFFE3E4F7);

  static const safe = Color(0xFF166534);
  static const safeTint = Color(0xFFE8F6EC);
  static const careful = Color(0xFF92400E);
  static const carefulTint = Color(0xFFFDF1DC);
  static const danger = Color(0xFFB91C1C);
  static const dangerTint = Color(0xFFFDE8E8);
  static const unknown = Color(0xFF334155);
  static const unknownTint = Color(0xFFECEFF3);
}

abstract final class UsisaRadius {
  static const card = 28.0;
  static const sheet = 36.0;
}

ThemeData buildUsisaTheme() {
  const text = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: UsisaColors.primary,
    primary: UsisaColors.primary,
    onPrimary: Colors.white,
    surface: UsisaColors.surface,
    onSurface: UsisaColors.ink,
    onSurfaceVariant: UsisaColors.inkMuted,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Rubik',
    scaffoldBackgroundColor: UsisaColors.background,
    textTheme: text.apply(bodyColor: UsisaColors.ink, displayColor: UsisaColors.ink),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values) platform: UsisaPageTransitionsBuilder(),
      },
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      indicatorColor: UsisaColors.lilac,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Rubik',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: UsisaColors.ink,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? UsisaColors.primary : UsisaColors.inkMuted,
        ),
      ),
    ),
  );
}
