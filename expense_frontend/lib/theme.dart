import 'package:flutter/material.dart';

class AppTheme {
  // Ocean Professional palette from style guide
  static const Color primary = Color(0xFF1E3A8A); // #1E3A8A
  static const Color secondary = Color(0xFFF59E0B); // #F59E0B
  static const Color success = Color(0xFF059669); // #059669
  static const Color error = Color(0xFFDC2626); // #DC2626
  static const Color background = Color(0xFFF3F4F6); // #F3F4F6
  static const Color surface = Color(0xFFFFFFFF); // #FFFFFF
  static const Color text = Color(0xFF111827); // #111827

  // PUBLIC_INTERFACE
  static ThemeData light() {
    /** Builds the app ThemeData using Ocean Professional palette. */
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 1.5,
        color: surface,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: surface,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
    );
  }
}
