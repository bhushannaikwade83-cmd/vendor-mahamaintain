import 'package:flutter/material.dart';

class AppTheme {
  // Kotlin exact colors from app.html
  static const Color saffron = Color(0xFFF25C05);
  static const Color saffronLight = Color(0xFFFF8534);
  static const Color saffronDark = Color(0xFFB84300);
  static const Color saffron50 = Color(0xFFFFF3EC);
  static const Color saffron100 = Color(0xFFFFE3D1);

  static const Color gold = Color(0xFFE5A100);
  static const Color teal = Color(0xFF00A693);
  static const Color tealDark = Color(0xFF00695D);

  static const Color bgLight = Color(0xFFF4F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF545470);
  static const Color textTertiary = Color(0xFF84849C);
  static const Color borderColor = Color(0xFFEAEAF0);

  // Legacy aliases for compatibility
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: saffron,
      scaffoldBackgroundColor: bgLight,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: saffron,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: transparent,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0,
        ),
        bodySmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textTertiary,
          letterSpacing: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: const Color.fromARGB(89, 255, 98, 0),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: saffron,
          side: const BorderSide(color: saffron, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: saffron, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: saffron,
        secondary: teal,
        surface: cardLight,
        error: const Color(0xFFDC2626),
      ),
    );
  }

  static const Color transparent = Color(0x00000000);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: saffron,
      scaffoldBackgroundColor: black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.dark(
        primary: saffron,
        secondary: teal,
        surface: const Color(0xFF1A1A1A),
        error: const Color(0xFFCF6679),
      ),
    );
  }
}
