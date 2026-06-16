import 'package:flutter/material.dart';

/// DeoReoNem product design tokens
class AppTokens {
  // Colors
  static const bgIvory = Color(0xFFFCF9F5);
  static const surfaceWarm = Color(0xFFFFFEFC);
  static const surfaceElevated = Color(0xFFF8F5F0);
  static const sagePrimary = Color(0xFF5B8C6B);
  static const sagePressed = Color(0xFF4D7A5C);
  static const textPrimary = Color(0xFF3A3530);
  static const textSecondary = Color(0xFF7A7570);
  static const textMuted = Color(0xFFA09A94);
  static const borderWarm = Color(0xFFEDE7DD);
  static const glowAmber = Color(0xFFD4A96A);
  static const errorMuted = Color(0xFFC47A6A);

  // Spacing
  static const pagePadding = EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
  static const sectionGap = 28.0;
  static const cardPadding = EdgeInsets.all(20.0);
  static const buttonGap = 10.0;

  // Radii
  static const radiusLarge = 24.0;
  static const radiusCard = 16.0;
  static const radiusButton = 12.0;
  static const radiusInput = 12.0;

  // Typography
  static TextStyle get titleHero => const TextStyle(
    fontSize: 44, fontWeight: FontWeight.w200, color: textPrimary, letterSpacing: 2);
  static TextStyle get titleScreen => const TextStyle(
    fontSize: 22, fontWeight: FontWeight.w400, color: textPrimary);
  static TextStyle get body => const TextStyle(
    fontSize: 14, color: textSecondary, height: 1.5);
  static TextStyle get bodyMuted => TextStyle(
    fontSize: 13, color: textMuted.withOpacity(0.8), height: 1.4);
  static TextStyle get label => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary);
  static TextStyle get caption => TextStyle(
    fontSize: 11, color: textMuted.withOpacity(0.7));
  static TextStyle get buttonPrimary => const TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white);
  static TextStyle get buttonSecondary => const TextStyle(
    fontSize: 14, color: textPrimary);
}
