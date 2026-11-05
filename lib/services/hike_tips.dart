import 'package:flutter/material.dart';

import '../services/weather_service.dart';

/// One piece of advice drawn from the live forecast.
class HikeTip {
  final IconData icon;
  final String text;
  final bool urgent;

  const HikeTip(this.icon, this.text, {this.urgent = false});
}

/// Turns a forecast into practical advice.
///
/// Rules are ordered by consequence: anything that could get somebody hurt
/// comes before anything that would merely make them uncomfortable.
class HikeTips {
  HikeTips._();

  static List<HikeTip> forConditions(TrailConditions c, String difficulty) {
    final List<HikeTip> tips = <HikeTip>[];

    final DayConditions? today =
        c.forecast.isEmpty ? null : c.forecast.first;
    final int code = today?.weatherCode ?? -1;
    final double maxT = today?.maxTempC ?? double.nan;
    final double minT = today?.minTempC ?? double.nan;
    final double rain = c.dailyRainMm;
    final double wind = _kph(c.windSummary);

    // WMO 95 and above is thunderstorm, which outranks everything else.
    if (code >= 95) {
      tips.add(const HikeTip(
        Icons.thunderstorm_outlined,
        'Thunderstorms forecast. Turn back if you hear thunder - a ridge '
            'or a summit is the worst place to be caught in one.',
        urgent: true,
      ));
    }

    if (c.safetyScore < 50) {
      tips.add(const HikeTip(
        Icons.report_problem_outlined,
        'Conditions score poorly today. Consider postponing, or choose a '
            'lower and shorter trail instead.',
        urgent: true,
      ));
    }

    if (code == 65 || code == 67 || code == 82 || rain >= 15) {
      tips.add(const HikeTip(
        Icons.beach_access_outlined,
        'Heavy rain. Bring a raincoat rather than an umbrella - an '
            'umbrella is useless in wind and occupies a hand you need.',
      ));
      tips.add(const HikeTip(
        Icons.landslide_outlined,
        'Wet ground means slick rock and a real landslide risk on the '
            'steep sections. Allow extra time and watch your footing.',
      ));
    } else if (code == 63 || code == 81 || rain >= 5) {
      tips.add(const HikeTip(
        Icons.beach_access_outlined,
        'Rain expected. Pack a raincoat, and keep your phone and power '
            'bank in a dry bag or a sealed plastic pouch.',
      ));
    } else if ((code >= 51 && code <= 61) || code == 80 || rain >= 0.5) {
      tips.add(const HikeTip(
        Icons.water_drop_outlined,
        'Light rain or drizzle. A packable rain jacket is enough, but '
            'rock and tree roots will still be slippery.',
      ));
    }

    if (code == 45 || code == 48) {
      tips.add(const HikeTip(
        Icons.foggy,
        'Fog expected. Stay on the marked path, keep your group in sight, '
            'and start the hike in the app so Backtrack can retrace your '
            'route if visibility closes in.',
      ));
    }

    if (maxT >= 32) {
      tips.add(HikeTip(
        Icons.wb_sunny_outlined,
        'Hot day, up to ${maxT.round()}C. Carry at least two litres of '
            'water and start early to miss the midday sun.',
      ));
    } else if (code >= 0 && code <= 2 && maxT >= 27) {
      tips.add(const HikeTip(
        Icons.wb_sunny_outlined,
        'Clear and warm. Sunscreen, a hat and long sleeves - there is '
            'little shade above the treeline.',
      ));
    }

    if (minT <= 18) {
      tips.add(HikeTip(
        Icons.ac_unit_outlined,
        'It drops to about ${minT.round()}C. Pack a warm layer for the '
            'summit and for an early start.',
      ));
    }

    if (wind >= 30) {
      tips.add(HikeTip(
        Icons.air_rounded,
        'Strong wind, around ${wind.round()} km/h. Exposed ridges will be '
            'hard going - secure loose gear and skip the summit if it '
            'gets worse.',
      ));
    } else if (wind >= 20) {
      tips.add(const HikeTip(
        Icons.air_rounded,
        'Breezy on the ridges. A windbreaker is worth the space.',
      ));
    }

    if (difficulty == 'Advanced') {
      tips.add(const HikeTip(
        Icons.hiking_rounded,
        'Advanced trail. Tell somebody your plan, join a group, and start '
            'the hike in the app so your party can see where you are.',
      ));
    }

    if (tips.isEmpty) {
      tips.add(const HikeTip(
        Icons.check_circle_outline,
        'Good conditions. Bring water and a light layer, and tell somebody '
            'when you expect to be back.',
      ));
    }

    // Five is as much as anyone reads before setting off.
    return tips.length > 5 ? tips.sublist(0, 5) : tips;
  }

  /// Wind arrives as a sentence, so pull the first number out of it.
  /// A missing figure yields NaN, and every comparison against NaN is
  /// false, which is exactly the right behaviour here.
  static double _kph(String summary) {
    final RegExpMatch? m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(summary);
    if (m == null) return double.nan;
    return double.tryParse(m.group(1)!) ?? double.nan;
  }
}