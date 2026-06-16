import 'package:flutter/material.dart';
import 'design/app_tokens.dart';

class AppTheme {
  static const Color background = AppTokens.bgIvory;
  static const Color surface = AppTokens.surfaceWarm;
  static const Color border = AppTokens.borderWarm;
  static const Color primaryText = AppTokens.textPrimary;
  static const Color secondaryText = AppTokens.textSecondary;
  static const Color accent = AppTokens.sagePrimary;
  static const Color drop = Color(0xFFC4A882);

  static ThemeData get themeData => ThemeData(
        scaffoldBackgroundColor: AppTokens.bgIvory,
        colorScheme: ColorScheme.light(
          primary: AppTokens.sagePrimary,
          surface: AppTokens.surfaceWarm,
          onPrimary: Colors.white,
          onSurface: AppTokens.textPrimary,
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
            color: AppTokens.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppTokens.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppTokens.textPrimary,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppTokens.textSecondary,
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
            foregroundColor: AppTokens.textSecondary,
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
