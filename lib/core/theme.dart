import 'package:flutter/material.dart';

/// Pregnancy mode: soft coral. Baby mode (Phase 3+): soft teal.
class AppTheme {
  static ThemeData pregnancy() => _base(seed: const Color(0xFFE8836F));

  static ThemeData baby() => _base(seed: const Color(0xFF4DB6AC));

  static ThemeData _base({required Color seed}) {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Gentle rise instead of the zooming default — calmer for a
      // monitoring app used half-asleep.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: scheme.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      navigationBarTheme: const NavigationBarThemeData(height: 72),
    );
  }
}
