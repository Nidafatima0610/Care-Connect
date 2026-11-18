import 'package:flutter/material.dart';

/// CareConnect Design System Color Palette.
///
/// Features a distinguished healthcare aesthetic:
/// - Deep Navy: Trust, authority, clinical excellence
/// - Sophisticated Teal: Innovation, calm, patient-centric action
/// - Warm Ivory & Soft Neutrals: Warmth, readability, comfort
/// - Subtle Mint: Health vitality and affirmative status
/// - Warm Amber: Ratings and badges
/// - Coral: Caution, alerts, and critical actions
///
/// Strictly NO purple or generic template gradients.
abstract final class AppColors {
  // Deep Navy Palette
  static const Color navy950 = Color(0xFF09121F);
  static const Color navy900 = Color(0xFF0E1A2D);
  static const Color navy800 = Color(0xFF162740);
  static const Color navy700 = Color(0xFF1E3557);
  static const Color navy600 = Color(0xFF2C4A73);
  static const Color navy500 = Color(0xFF3F6495);
  static const Color navy100 = Color(0xFFE5ECF6);
  static const Color navy50 = Color(0xFFF3F6FA);

  // Sophisticated Teal Palette
  static const Color teal900 = Color(0xFF0C4A5A);
  static const Color teal800 = Color(0xFF0E5C6F);
  static const Color teal700 = Color(0xFF0E7490); // Primary Brand Accent
  static const Color teal600 = Color(0xFF0891B2);
  static const Color teal500 = Color(0xFF06B6D4);
  static const Color teal200 = Color(0xFFA5F3FC);
  static const Color teal100 = Color(0xFFCFFAFE);
  static const Color teal50 = Color(0xFFF0FDFA);

  // Warm Ivory & Neutral Surfaces
  static const Color ivory = Color(0xFFFBFBFA);
  static const Color surfaceWarm = Color(0xFFF6F5F0);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);

  // Subtle Mint (Vitality / Status)
  static const Color mint = Color(0xFF10B981);
  static const Color mintDark = Color(0xFF047857);
  static const Color mintLight = Color(0xFFD1FAE5);
  static const Color mint50 = Color(0xFFECFDF5);

  // Warm Amber (Ratings / Attention)
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color amber50 = Color(0xFFFFFBEB);

  // Soft Coral / Red (Urgent / Warning)
  static const Color coral = Color(0xFFEF4444);
  static const Color coralLight = Color(0xFFFEE2E2);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF0E1A2D);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFFCBD5E1);
  static const Color textOnNavy = Color(0xFFFFFFFF);
  static const Color textOnTeal = Color(0xFFFFFFFF);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF080E18);
  static const Color darkSurface = Color(0xFF0E1A2D);
  static const Color darkSurfaceCard = Color(0xFF14233C);
  static const Color darkBorder = Color(0xFF1E3557);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
