import 'package:flutter/material.dart';

/// DeoReoNem product design tokens — extracted from Reference A
class AppTokens {
  // Primary
  static const sagePrimary = Color(0xFF4A6D57);
  static const sageLight = Color(0xFF91B87A);

  // Neutrals
  static const ivory = Color(0xFFF8F4F4);
  static const warmWhite = Color(0xFFFFF0F6);
  static const sand = Color(0xFFA7AD6A);
  static const warmGray = Color(0xFFA7A29A);
  static const charcoal = Color(0xFF2D3E88);

  // Accent
  static const amber = Color(0xFFD4A96A);
  static const softBlue = Color(0xFF8FA7E7);
  static const lavender = Color(0xFFB8AAC5);

  // Functional
  static const bgIvory = Color(0xFFF8F4F4);
  static const surfaceWarm = Color(0xFFFFFEFC);
  static const textPrimary = Color(0xFF2D3530);
  static const textSecondary = Color(0xFFA7A29A);
  static const textCaption = Color(0xFFA7A29A);
  static const textMuted = Color(0xFFA7A29A);
  static const borderWarm = Color(0xFFE8E4DE);
  static const glowAmber = Color(0xFFD4A96A);
  static const errorMuted = Color(0xFFC47A6A);

  // Typography (Pretendard-based, use system font fallback)
  static TextStyle get titleBanner => const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w300,
      color: textPrimary,
      letterSpacing: 1);
  static TextStyle get titleHero => const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w300,
      color: textPrimary,
      letterSpacing: 1);
  static TextStyle get titleScreen => const TextStyle(
      fontSize: 24, fontWeight: FontWeight.w500, color: textPrimary);
  static TextStyle get heading => const TextStyle(
      fontSize: 24, fontWeight: FontWeight.w500, color: textPrimary);
  static TextStyle get body => const TextStyle(
      fontSize: 16, color: textPrimary, height: 1.5);
  static TextStyle get bodyMuted => TextStyle(
      fontSize: 13, color: textSecondary.withOpacity(0.8), height: 1.4);
  static TextStyle get label => const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary);
  static TextStyle get caption => const TextStyle(
      fontSize: 13, color: textSecondary);
  static TextStyle get buttonPrimary => const TextStyle(
      fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white);
  static TextStyle get buttonSecondary => const TextStyle(
      fontSize: 14, color: textPrimary);

  // Spacing
  static const pagePadding =
      EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
  static const sectionGap = 24.0;
  static const cardPadding = EdgeInsets.all(20.0);
  static const buttonGap = 10.0;

  // Radii
  static const radiusLarge = 20.0;
  static const radiusCard = 14.0;
  static const radiusButton = 12.0;
  static const radiusInput = 12.0;
}
