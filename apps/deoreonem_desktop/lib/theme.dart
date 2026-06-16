import 'package:flutter/material.dart';
import 'design/app_tokens.dart';

class AppTheme {
  static const Color background = Color(0xFFFCF9F5);
  static const Color surface = Color(0xFFFFFEFC);
  static const Color border = Color(0xFFEDE7DD);
  static const Color primaryText = Color(0xFF3A3530);
  static const Color secondaryText = Color(0xFF7A7570);
  static const Color accent = Color(0xFF5B8C6B);
  static const Color drop = Color(0xFFC4A882);

  static ThemeData get themeData => ThemeData(
        scaffoldBackgroundColor: AppTokens.bgIvory,
        colorScheme: ColorScheme.light(
          primary: accent,
          surface: surface,
          onPrimary: Colors.white,
          onSurface: primaryText,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppTokens.surfaceWarm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: primaryText,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
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
            backgroundColor: AppTokens.sagePrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            ),
            side: BorderSide(color: AppTokens.borderWarm),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: secondaryText,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
            borderSide: BorderSide(color: AppTokens.borderWarm),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
            borderSide: BorderSide(color: AppTokens.borderWarm),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
            borderSide: BorderSide(color: AppTokens.sagePrimary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
