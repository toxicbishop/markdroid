import 'package:flutter/material.dart';

class AppTheme {
  // Common Colors
  static const Color success = Color(0xFF10B981);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
  static const Color accentLight = Color(0xFF2563EB); // Blue 600
  static const Color accentDark = Color(0xFF3B82F6); // Blue 500

  // Light Theme Colors
  static const Color primaryLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color onSurfaceLight = Color(0xFF1E293B);
  static const Color onSurfaceMutedLight = Color(0xFF64748B);

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);
  static const Color onSurfaceMutedDark = Color(0xFF94A3B8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: accentLight,
          surface: primaryLight,
          onSurface: onSurfaceLight,
          onSurfaceVariant: onSurfaceMutedLight,
          surfaceContainer: surfaceVariantLight,
          error: errorLight,
        ),
        scaffoldBackgroundColor: primaryLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryLight,
          foregroundColor: onSurfaceLight,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: onSurfaceLight,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentLight,
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
            foregroundColor: accentLight,
            side: const BorderSide(color: accentLight, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE2E8F0),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: onSurfaceMutedLight),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentLight,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: accentDark,
          surface: primaryDark,
          onSurface: onSurfaceDark,
          onSurfaceVariant: onSurfaceMutedDark,
          surfaceContainer: surfaceVariantDark,
          error: errorDark,
        ),
        scaffoldBackgroundColor: primaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryDark,
          foregroundColor: onSurfaceDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: onSurfaceDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentDark,
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
            foregroundColor: accentDark,
            side: const BorderSide(color: accentDark, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF334155),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: onSurfaceMutedDark),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentDark,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      );
}

// Extension to make semantic colors easy to access from context
extension ThemeColors on BuildContext {
  Color get appPrimary => Theme.of(this).scaffoldBackgroundColor;
  Color get appSurface => Theme.of(this).cardTheme.color!;
  Color get appSurfaceVariant => Theme.of(this).colorScheme.surfaceContainer;
  Color get appOnSurface => Theme.of(this).colorScheme.onSurface;
  Color get appOnSurfaceMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appAccent => Theme.of(this).colorScheme.primary;
  Color get appSuccess => AppTheme.success;
  Color get appError => Theme.of(this).colorScheme.error;
}
