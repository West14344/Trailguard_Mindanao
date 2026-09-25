import "package:flutter/material.dart";

/// Palette pulled from a rainforest trail.
///
/// Dark mode is tuned for night use rather than just inverted. Three
/// rules drive it: surfaces stay near-black but never pure black, text
/// sits well below pure white, and accents are desaturated so nothing
/// on screen is brighter than it needs to be. Filled buttons become
/// dark with coloured text, since a large bright fill is the main
/// source of glare in a dark interface.
class AppColors {
  static bool get _dark => AppTheme.isDark;

  // Greens, dark to light
  static Color get pine =>
      _dark ? const Color(0xFFA9BFB1) : const Color(0xFF0B2E1E);
  static Color get forest =>
      _dark ? const Color(0xFF4E9168) : const Color(0xFF1B7A4B);
  static Color get fern =>
      _dark ? const Color(0xFF5C9E76) : const Color(0xFF3EA76B);
  static Color get moss =>
      _dark ? const Color(0xFF7BA68C) : const Color(0xFF8ECCA6);
  static Color get mist =>
      _dark ? const Color(0xFF1A241E) : const Color(0xFFD3E8DA);

  // Surfaces. Near-black, with cards barely lifted so edges read without
  // the page glowing.
  static Color get paper =>
      _dark ? const Color(0xFF0E120F) : const Color(0xFFEAF2EA);
  static Color get card =>
      _dark ? const Color(0xFF151A16) : const Color(0xFFFBFDFA);
  static Color get line =>
      _dark ? const Color(0xFF242C26) : const Color(0xFFCBDDCF);
  static Color get fill =>
      _dark ? const Color(0xFF1A201C) : const Color(0xFFDDEADF);

  // Text. Well below pure white, which is the single biggest cause of
  // eye strain at night.
  static Color get ink =>
      _dark ? const Color(0xFFC3CCC6) : const Color(0xFF0E2418);
  static Color get inkSoft =>
      _dark ? const Color(0xFF7E8C84) : const Color(0xFF52705F);

  // Reserved for meaning. Muted so a warning reads as a warning without
  // burning a hole in a dark screen.
  static Color get blaze =>
      _dark ? const Color(0xFFB4783F) : const Color(0xFFE3712B);
  static Color get alert =>
      _dark ? const Color(0xFFAC5A51) : const Color(0xFFB3261E);

  /// Fill behind a primary button. Dark mode keeps it dark, so the
  /// button is outlined and tinted rather than a bright block.
  static Color get accentFill =>
      _dark ? const Color(0xFF16221B) : const Color(0xFF1B7A4B);

  static Color get alertFill =>
      _dark ? const Color(0xFF221513) : const Color(0xFFB3261E);

  /// Text on a filled button. White in light mode; the accent colour
  /// itself in dark mode, since the fill behind it is now dark.
  static Color get onAccent =>
      _dark ? const Color(0xFF6FAF87) : Colors.white;

  static Color get onAlert =>
      _dark ? const Color(0xFFC4736A) : Colors.white;

  /// Border for filled buttons in dark mode, where the fill alone is
  /// too subtle to define the shape.
  static Color get accentBorder =>
      _dark ? const Color(0xFF2F4A39) : Colors.transparent;

  static Color get alertBorder =>
      _dark ? const Color(0xFF4A2F2C) : Colors.transparent;
}

class AppTheme {
  /// Rebuilds the app when the mode changes.
  static final modeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool isDark = false;

  static void setMode(ThemeMode mode) {
    modeNotifier.value = mode;
  }

  /// Called by the app when the platform brightness is known, so
  /// ThemeMode.system resolves correctly.
  static void resolve(BuildContext context) {
    final mode = modeNotifier.value;
    isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
  }

  static String get modeLabel => switch (modeNotifier.value) {
        ThemeMode.dark => "Dark",
        ThemeMode.light => "Light",
        ThemeMode.system => "Match device",
      };

  static String get modeCode => switch (modeNotifier.value) {
        ThemeMode.dark => "dark",
        ThemeMode.light => "light",
        ThemeMode.system => "system",
      };

  static ThemeMode modeFromCode(String? code) => switch (code) {
        "dark" => ThemeMode.dark,
        "system" => ThemeMode.system,
        _ => ThemeMode.light,
      };

  static ThemeData build() {
    final dark = isDark;

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: AppColors.forest,
        secondary: AppColors.fern,
        surface: AppColors.paper,
        onPrimary: AppColors.onAccent,
      ),
      splashColor: AppColors.forest.withAlpha(20),
      highlightColor: AppColors.forest.withAlpha(12),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.card),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.ink),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 30,
          height: 1.15,
          // Tight spacing thins strokes on a dark field, so relax it.
          letterSpacing: dark ? -0.3 : -0.8,
          fontWeight: dark ? FontWeight.w600 : FontWeight.w700,
          color: AppColors.pine,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.2,
          letterSpacing: dark ? -0.1 : -0.5,
          fontWeight: dark ? FontWeight.w600 : FontWeight.w700,
          color: AppColors.pine,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: dark ? FontWeight.w500 : FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: dark ? FontWeight.w500 : FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: dark ? 1.55 : 1.4,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          height: dark ? 1.55 : 1.4,
          color: AppColors.inkSoft,
        ),
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
