import 'package:flutter/material.dart';

/// Palette pulled from a rainforest trail: wet canopy, fern light, the
/// pale green of laminated topo paper, and the orange of a ranger post.
class AppColors {
  // Greens, dark to light
  static const pine = Color(0xFF0B2E1E);      // deepest — canopy shadow
  static const forest = Color(0xFF1B7A4B);    // primary actions
  static const fern = Color(0xFF3EA76B);      // lighter accent
  static const moss = Color(0xFF8ECCA6);      // soft highlight
  static const mist = Color(0xFFD3E8DA);      // secondary button fill

  // Surfaces
  static const paper = Color(0xFFEAF2EA);     // app background
  static const card = Color(0xFFFBFDFA);      // cards, fields
  static const line = Color(0xFFCBDDCF);      // borders
  static const fill = Color(0xFFDDEADF);      // inert fills, placeholders

  // Text
  static const ink = Color(0xFF0E2418);       // headings and body
  static const inkSoft = Color(0xFF52705F);   // captions, hints

  // Non-green, reserved for meaning only
  static const blaze = Color(0xFFE3712B);     // hazard / caution
  static const alert = Color(0xFFB3261E);     // critical alert
}

class AppTheme {
  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        secondary: AppColors.fern,
        surface: AppColors.paper,
      ),
      splashColor: const Color(0x1A1B7A4B),
      highlightColor: const Color(0x0F1B7A4B),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 30,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: AppColors.pine,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.pine,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.ink),
        bodySmall: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}

/// Shared shapes so every card in the app agrees with itself.
class AppRadius {
  static const card = BorderRadius.all(Radius.circular(16));
  static const pill = BorderRadius.all(Radius.circular(100));
  static const field = BorderRadius.all(Radius.circular(12));
}