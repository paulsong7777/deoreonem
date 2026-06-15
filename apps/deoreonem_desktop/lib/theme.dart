import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFFBF8F4); // warmer
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E4DF);
  static const Color primaryText = Color(0xFF4A4540); // warm gray
  static const Color secondaryText = Color(0xFF8C8580); // warm gray, not cold
  static const Color accent = Color(0xFF5B8C6B); // sage green
  static const Color drop = Color(0xFFC4A882);

  static ThemeData get themeData => ThemeData(
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.light(
          primary: accent,
          surface: surface,
          onPrimary: Colors.white,
          onSurface: primaryText,
        ),
        cardTheme: CardThemeData(
          elevation: 0.3,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: primaryText,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: primaryText,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: primaryText,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: secondaryText,
            height: 1.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B8C6B),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: Color(0xFFDDD8D0)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: secondaryText,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accent, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
}
