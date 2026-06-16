import 'package:flutter/material.dart';

/// Sıcak içecek temalı palet (kahve/çay tonları).
class AppTheme {
  static const _coffee = Color(0xFF6F4E37); // kahve kahverengi
  static const _cream = Color(0xFFF5EBDD); // krema
  static const _accent = Color(0xFFC8853A); // bal/karamel
  static const _dark = Color(0xFF2E211B);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _coffee,
      primary: _coffee,
      secondary: _accent,
      surface: _cream,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFBF6EF),
      appBarTheme: const AppBarTheme(
        backgroundColor: _coffee,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _coffee,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D5C5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D5C5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: _accent.withValues(alpha: 0.25),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall:
            TextStyle(fontWeight: FontWeight.bold, color: _dark),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: _dark),
      ),
    );
  }
}
