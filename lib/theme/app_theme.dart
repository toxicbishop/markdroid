import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFF4F8EF7);
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceVariant = Color(0xFF0F3460);
  static const Color onSurface = Color(0xFFE0E6F8);
  static const Color onSurfaceMuted = Color(0xFF8A9BC4);
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFEF5350);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          surface: primary,
          onSurface: onSurface,
          error: error,
        ),
        scaffoldBackgroundColor: primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: onSurface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardTheme(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF1E2D5A), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: const BorderSide(color: accent, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E2D5A),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: onSurfaceMuted),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      );
}
