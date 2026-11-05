import 'dart:async';

import 'package:flutter/material.dart';

/// Which seasonal skin is in force today.
enum Season {
  none,
  lunarNewYear,
  valentines,
  ashWednesday,
  maundyThursday,
  goodFriday,
  blackSaturday,
  easter,
  halloween,
  christmas,
}

/// The handful of colours a season is allowed to change.
///
/// Alert red, the safety-score colours and every text ink stay fixed. A
/// seasonal skin must never make an emergency harder to recognise.
class SeasonalPalette {
  final Season season;
  final String label;
  final IconData icon;

  /// Stands in for the usual forest accent: buttons, links, active states.
  final Color accent;

  /// Stands in for the fern secondary: chips and quieter accents.
  final Color accentSoft;

  /// Text and icons drawn on top of [accent].
  final Color onAccent;

  /// One short line for the dashboard banner.
  final String greeting;

  const SeasonalPalette({
    required this.season,
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.greeting,
  });
}

/// Swaps the accent colours by calendar date, and switches over at
/// midnight without the app being restarted.
class SeasonalThemes {
  SeasonalThemes._();

  /// Switched off from Profile, for anyone who wants the plain app.
  static bool enabled = true;

  /// Valentine runs for the whole of February. Set this to 14 to limit it
  /// to the fortnight instead.
  static const int valentinesEndDay = 29;

  static final ValueNotifier<Season> notifier =
      ValueNotifier<Season>(Season.none);

  static Timer? _timer;

  // --------------------------------------------------------------- seasons

  static Season seasonFor(DateTime now) {
    final DateTime d = DateTime(now.year, now.month, now.day);

    // Holy Week outranks everything: these are single, fixed observances
    // and a Valentine pink on Good Friday would be crass.
    final DateTime easter = easterSunday(d.year);
    if (_same(d, easter)) return Season.easter;
    if (_same(d, _minus(easter, 1))) return Season.blackSaturday;
    if (_same(d, _minus(easter, 2))) return Season.goodFriday;
    if (_same(d, _minus(easter, 3))) return Season.maundyThursday;
    if (_same(d, _minus(easter, 46))) return Season.ashWednesday;

    // Lunar New Year: the day itself and the two that follow.
    final DateTime? cny = lunarNewYear(d.year);
    if (cny != null) {
      final int diff = d.difference(cny).inDays;
      if (diff >= 0 && diff <= 2) return Season.lunarNewYear;
    }

    // Halloween into Undas.
    if ((d.month == 10 && d.day == 31) || (d.month == 11 && d.day <= 3)) {
      return Season.halloween;
    }

    if (d.month == 12) return Season.christmas;

    if (d.month == 2 && d.day <= valentinesEndDay) return Season.valentines;

    return Season.none;
  }

  static SeasonalPalette? paletteFor(DateTime now) {
    if (!enabled) return null;
    return palettes[seasonFor(now)];
  }

  static SeasonalPalette? get current => paletteFor(DateTime.now());

  // -------------------------------------------------------------- calendar

  /// Gregorian Easter, by the anonymous computus. Correct for the Western
  /// church, which is the one that matters here.
  static DateTime easterSunday(int year) {
    final int a = year % 19;
    final int b = year ~/ 100;
    final int c = year % 100;
    final int dd = b ~/ 4;
    final int e = b % 4;
    final int f = (b + 8) ~/ 25;
    final int g = (b - f + 1) ~/ 3;
    final int h = (19 * a + b - dd - g + 15) % 30;
    final int i = c ~/ 4;
    final int k = c % 4;
    final int l = (32 + 2 * e + 2 * i - h - k) % 7;
    final int m = (a + 11 * h + 22 * l) ~/ 451;
    final int month = (h + l - 7 * m + 114) ~/ 31;
    final int day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Lunar New Year is lunisolar and cannot be derived with a short
  /// formula, so these are tabulated. Years outside the table simply get
  /// no Lunar New Year theme rather than a wrong one.
  static const Map<int, List<int>> lunarNewYearDates = <int, List<int>>{
    2026: <int>[2, 17],
    2027: <int>[2, 6],
    2028: <int>[1, 26],
    2029: <int>[2, 13],
    2030: <int>[2, 3],
    2031: <int>[1, 23],
    2032: <int>[2, 11],
    2033: <int>[1, 31],
    2034: <int>[2, 19],
    2035: <int>[2, 8],
    2036: <int>[1, 28],
    2037: <int>[2, 15],
    2038: <int>[2, 4],
    2039: <int>[1, 24],
    2040: <int>[2, 12],
  };

  static DateTime? lunarNewYear(int year) {
    final List<int>? md = lunarNewYearDates[year];
    if (md == null) return null;
    return DateTime(year, md[0], md[1]);
  }

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _minus(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day - days);

  // -------------------------------------------------------------- palettes

  static const Map<Season, SeasonalPalette> palettes =
      <Season, SeasonalPalette>{
    Season.lunarNewYear: SeasonalPalette(
      season: Season.lunarNewYear,
      label: 'Lunar New Year',
      icon: Icons.celebration_outlined,
      // Gold rather than the traditional red, so emergency red stays the
      // only red in the app.
      accent: Color(0xFFB8860B),
      accentSoft: Color(0xFFD4A017),
      onAccent: Colors.white,
      greeting: 'Kung Hei Fat Choi. Safe trails this new year.',
    ),
    Season.valentines: SeasonalPalette(
      season: Season.valentines,
      label: 'Valentine',
      icon: Icons.favorite_outline,
      accent: Color(0xFFC2185B),
      accentSoft: Color(0xFFE2698F),
      onAccent: Colors.white,
      greeting: 'Take someone with you. Nobody should hike alone.',
    ),
    Season.ashWednesday: SeasonalPalette(
      season: Season.ashWednesday,
      label: 'Ash Wednesday',
      icon: Icons.church_outlined,
      accent: Color(0xFF5E4B8B),
      accentSoft: Color(0xFF7E6BA8),
      onAccent: Colors.white,
      greeting: 'Ash Wednesday. A quiet start to Lent.',
    ),
    Season.maundyThursday: SeasonalPalette(
      season: Season.maundyThursday,
      label: 'Maundy Thursday',
      icon: Icons.church_outlined,
      accent: Color(0xFF4A3F75),
      accentSoft: Color(0xFF6B5F99),
      onAccent: Colors.white,
      greeting: 'Maundy Thursday. Trails are busy this week.',
    ),
    Season.goodFriday: SeasonalPalette(
      season: Season.goodFriday,
      label: 'Good Friday',
      icon: Icons.church_outlined,
      accent: Color(0xFF3E3A4A),
      accentSoft: Color(0xFF5A5468),
      onAccent: Colors.white,
      greeting: 'Good Friday.',
    ),
    Season.blackSaturday: SeasonalPalette(
      season: Season.blackSaturday,
      label: 'Black Saturday',
      icon: Icons.church_outlined,
      accent: Color(0xFF2E2B36),
      accentSoft: Color(0xFF4A4654),
      onAccent: Colors.white,
      greeting: 'Black Saturday.',
    ),
    Season.easter: SeasonalPalette(
      season: Season.easter,
      label: 'Easter Sunday',
      icon: Icons.wb_twilight,
      accent: Color(0xFF9A7B16),
      accentSoft: Color(0xFFC9A227),
      onAccent: Colors.white,
      greeting: 'Happy Easter.',
    ),
    Season.halloween: SeasonalPalette(
      season: Season.halloween,
      label: 'Undas',
      icon: Icons.nightlight_round,
      accent: Color(0xFFD1700F),
      accentSoft: Color(0xFF6D4C9F),
      onAccent: Colors.white,
      greeting: 'Undas. Carry a light, the trails go dark early.',
    ),
    Season.christmas: SeasonalPalette(
      season: Season.christmas,
      label: 'Christmas',
      icon: Icons.park_outlined,
      accent: Color(0xFF0F6B3C),
      accentSoft: Color(0xFFC9A227),
      onAccent: Colors.white,
      greeting: 'Maligayang Pasko. Expect colder, wetter trails.',
    ),
  };

  // ------------------------------------------------------------- real time

  /// Reads today's season and arranges to re-read it at midnight, so the
  /// theme turns over while the app is open.
  static void start() {
    refresh();
    _scheduleNext();
  }

  static void _scheduleNext() {
    _timer?.cancel();
    final DateTime now = DateTime.now();
    final DateTime midnight = DateTime(now.year, now.month, now.day + 1);
    Duration wait = midnight.difference(now) + const Duration(seconds: 2);
    if (wait.isNegative) wait = const Duration(minutes: 1);
    _timer = Timer(wait, () {
      refresh();
      _scheduleNext();
    });
  }

  /// Also call this when the app resumes: a phone asleep across midnight
  /// never fires the timer.
  static void refresh() {
    final Season s = enabled ? seasonFor(DateTime.now()) : Season.none;
    if (s != notifier.value) notifier.value = s;
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}