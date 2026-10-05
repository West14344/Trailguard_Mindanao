import "package:flutter/material.dart";

/// Palette pulled from a rainforest trail.
///
/// Dark mode targets a contrast ratio near 7:1 rather than the maximum.
/// Pure black behind near-white text measures about 21:1, which is where
/// halation comes from: the eye cannot settle and the text appears to
/// shimmer. Everything here is pulled toward a middle grey-green so the
/// screen reads as a dim page rather than a light source.
class AppColors {
  static bool get _dark => AppTheme.isDark;

  // Greens
  static Color get pine =>
      _dark ? const Color(0xFF9FB3A6) : const Color(0xFF0B2E1E);
  static Color get forest =>
      _dark ? const Color(0xFF5E8C70) : const Color(0xFF1B7A4B);
  static Color get fern =>
      _dark ? const Color(0xFF6B9A7D) : const Color(0xFF3EA76B);
  static Color get moss =>
      _dark ? const Color(0xFF7D9C88) : const Color(0xFF8ECCA6);
  static Color get mist =>
      _dark ? const Color(0xFF212A24) : const Color(0xFFD3E8DA);

  // Surfaces. Lifted off black so the difference between page and card
  // is felt rather than seen as a bright panel.
  static Color get paper =>
      _dark ? const Color(0xFF171C19) : const Color(0xFFEAF2EA);
  static Color get card =>
      _dark ? const Color(0xFF1E2521) : const Color(0xFFFBFDFA);
  static Color get line =>
      _dark ? const Color(0xFF2B332E) : const Color(0xFFCBDDCF);
  static Color get fill =>
      _dark ? const Color(0xFF232B26) : const Color(0xFFDDEADF);

  // Text. Around 8:1 against the page, which is comfortable to read for
  // long periods without the glare of near-white.
  static Color get ink =>
      _dark ? const Color(0xFFB4BEB7) : const Color(0xFF0E2418);
  static Color get inkSoft =>
      _dark ? const Color(0xFF7C8880) : const Color(0xFF52705F);

  // Reserved for meaning, muted so a warning registers without burning.
  static Color get blaze =>
      _dark ? const Color(0xFFA67A50) : const Color(0xFFE3712B);
  static Color get alert =>
      _dark ? const Color(0xFF9E6159) : const Color(0xFFB3261E);

  /// Buttons stay dark-filled with coloured text, so no large bright
  /// block ever sits on the screen.
  static Color get accentFill =>
      _dark ? const Color(0xFF1E2A22) : const Color(0xFF1B7A4B);
  static Color get alertFill =>
      _dark ? const Color(0xFF2A1D1B) : const Color(0xFFB3261E);
  static Color get onAccent =>
      _dark ? const Color(0xFF86B096) : Colors.white;
  static Color get onAlert =>
      _dark ? const Color(0xFFB07E76) : Colors.white;
  static Color get accentBorder =>
      _dark ? const Color(0xFF35483C) : Colors.transparent;
  static Color get alertBorder =>
      _dark ? const Color(0xFF4A3330) : Colors.transparent;
  /// The dark hero card on the dashboard and the avatar circle. In light
  /// mode this is the deep pine green; in dark mode it has to stay dark,
  /// otherwise it becomes the brightest block on the screen.
  static Color get heroFill =>
      _dark ? const Color(0xFF212B24) : const Color(0xFF0B2E1E);

  /// Text sitting on heroFill.
  static Color get onHero =>
      _dark ? const Color(0xFFB4BEB7) : Colors.white;

  static Color get onHeroSoft =>
      _dark ? const Color(0xFF8A968E) : const Color(0xFFC6DCCE);
}

class AppTheme {
  static final modeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool isDark = false;

  static void setMode(ThemeMode mode) {
    modeNotifier.value = mode;
  }

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
      splashColor: AppColors.forest.withAlpha(18),
      highlightColor: AppColors.forest.withAlpha(10),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.card),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.ink),
      ),
      textTheme: TextTheme(
        // Headings drop to a medium weight in dark mode. Bold strokes
        // bloom against a dark field and are the usual cause of the
        // shimmering effect on titles.
        displaySmall: TextStyle(
          fontSize: 29,
          height: 1.2,
          letterSpacing: dark ? 0 : -0.8,
          fontWeight: dark ? FontWeight.w500 : FontWeight.w700,
          color: AppColors.pine,
        ),
        headlineMedium: TextStyle(
          fontSize: 23,
          height: 1.25,
          letterSpacing: dark ? 0.1 : -0.5,
          fontWeight: dark ? FontWeight.w500 : FontWeight.w700,
          color: AppColors.pine,
        ),
        titleLarge: TextStyle(
          fontSize: 17.5,
          fontWeight: dark ? FontWeight.w500 : FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: dark ? FontWeight.w500 : FontWeight.w600,
          color: AppColors.ink,
        ),
        // Looser lines at night: dark text blocks read harder when tight.
        bodyMedium: TextStyle(
          fontSize: 14,
          height: dark ? 1.6 : 1.4,
          letterSpacing: dark ? 0.15 : 0,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          height: dark ? 1.6 : 1.4,
          letterSpacing: dark ? 0.1 : 0,
          color: AppColors.inkSoft,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
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

