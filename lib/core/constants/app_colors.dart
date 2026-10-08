import 'package:flutter/material.dart';

/// High-contrast, WCAG AAA compliant color palette
/// Specially optimized for visually impaired users and low-vision legibility.
class AppColors {
  AppColors._();

  // Dark High-Contrast Canvas
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1B1E28);
  static const Color surfaceElevated = Color(0xFF262A36);
  static const Color surfaceBright = Color(0xFF333848);

  // High-Visibility Accents
  static const Color highVisYellow = Color(0xFFFFD600);
  static const Color highVisYellowDark = Color(0xFFC7A500);

  // Status & Telemetry Indicators
  static const Color safeGreen = Color(0xFF00E676);
  static const Color safeGreenBg = Color(0xFF052B18);
  static const Color dangerRed = Color(0xFFFF334B);
  static const Color dangerRedBg = Color(0xFF3B0D14);
  static const Color warningOrange = Color(0xFFFF9100);
  static const Color warningOrangeBg = Color(0xFF361F05);

  // High-Contrast Neutral & Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD1D5DB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFF4B5563);
  static const Color borderHighContrast = Color(0xFFE5E7EB);

  // Caretaker Palette (Clean, professional monitoring)
  static const Color caretakerPrimary = Color(0xFF2563EB);
  static const Color caretakerSecondary = Color(0xFF3B82F6);
  static const Color caretakerAccent = Color(0xFF06B6D4);
}
