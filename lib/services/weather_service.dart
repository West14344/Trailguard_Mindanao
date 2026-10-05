import "dart:convert";
import "package:http/http.dart" as http;

/// Conditions for one day, with a safety score derived from them.
class DayConditions {
  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final double rainMm;
  final double windKph;
  final int weatherCode;
  final int safetyScore;

  const DayConditions({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.rainMm,
    required this.windKph,
    required this.weatherCode,
    required this.safetyScore,
  });

  String get summary =>
      "${WeatherService.describe(weatherCode)}, ${maxTempC.round()}C";

  String get rainfallRisk {
    if (rainMm >= 20) return "High";
    if (rainMm >= 5) return "Moderate";
    return "Low";
  }

  /// How many days ahead this is. Day 0 is today.
  int get daysAhead {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).difference(today).inDays;
  }

  /// Forecast accuracy drops off noticeably after about four days, so
  /// later days are marked rather than presented with equal confidence.
  bool get isLessCertain => daysAhead >= 4;

  /// Short weekday label for the forecast strip.
  String get shortDay {
    const names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    if (daysAhead == 0) return "Today";
    return names[date.weekday - 1];
  }

  /// "Today", "Tomorrow", then the weekday name.
  String get dayLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Tomorrow";

    const names = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return names[date.weekday - 1];
  }
}

/// Live conditions now, plus a short forecast so a hiker can pick the
/// better day rather than only seeing today.
class TrailConditions {
  final double temperatureC;
  final double precipitationMm;
  final double dailyRainMm;
  final double windKph;
  final int weatherCode;
  final int safetyScore;
  final List<DayConditions> forecast;

  const TrailConditions({
    required this.temperatureC,
    required this.precipitationMm,
    required this.dailyRainMm,
    required this.windKph,
    required this.weatherCode,
    required this.safetyScore,
    required this.forecast,
  });

  String get summary =>
      "${WeatherService.describe(weatherCode)}, ${temperatureC.round()}C";

  String get rainfallRisk {
    if (dailyRainMm >= 20) return "High";
    if (dailyRainMm >= 5) return "Moderate";
    return "Low";
  }

  String get windSummary => "${windKph.round()} km/h";

  /// The best day in the next three, so the app can suggest waiting.
  DayConditions? get bestDay {
    if (forecast.isEmpty) return null;
    var best = forecast.first;
    for (final d in forecast) {
      if (d.safetyScore > best.safetyScore) best = d;
    }
    return best;
  }

  /// True when a later day is clearly safer than today.
  bool get worthWaiting {
    final best = forecast.isEmpty ? null : bestDay;
    if (best == null || forecast.isEmpty) return false;
    return best.date.day != forecast.first.date.day &&
        best.safetyScore - safetyScore >= 15;
  }
}

class WeatherService {
  /// Open-Meteo is free and needs no API key.
  static Future<TrailConditions> fetch({
    required double latitude,
    required double longitude,
    required String difficulty,
  }) async {
    final uri = Uri.parse(
      "https://api.open-meteo.com/v1/forecast"
      "?latitude=$latitude&longitude=$longitude"
      "&current=temperature_2m,precipitation,weather_code,wind_speed_10m"
      "&daily=precipitation_sum,temperature_2m_max,temperature_2m_min,"
      "weather_code,wind_speed_10m_max"
      "&timezone=auto&forecast_days=7",
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception("Weather service returned ${response.statusCode}");
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final current = body["current"] as Map<String, dynamic>;
    final daily = body["daily"] as Map<String, dynamic>;

    final temp = (current["temperature_2m"] as num).toDouble();
    final precip = (current["precipitation"] as num?)?.toDouble() ?? 0;
    final wind = (current["wind_speed_10m"] as num?)?.toDouble() ?? 0;
    final code = (current["weather_code"] as num).toInt();

    final dates = (daily["time"] as List).cast<String>();
    final rains = (daily["precipitation_sum"] as List);
    final maxTemps = (daily["temperature_2m_max"] as List);
    final minTemps = (daily["temperature_2m_min"] as List);
    final codes = (daily["weather_code"] as List);
    final winds = (daily["wind_speed_10m_max"] as List);

    final forecast = <DayConditions>[];
    for (var i = 0; i < dates.length && i < 7; i++) {
      final rain = (rains[i] as num?)?.toDouble() ?? 0;
      final dayWind = (winds[i] as num?)?.toDouble() ?? 0;
      final dayCode = (codes[i] as num?)?.toInt() ?? 0;

      forecast.add(DayConditions(
        date: DateTime.parse(dates[i]),
        maxTempC: (maxTemps[i] as num?)?.toDouble() ?? 0,
        minTempC: (minTemps[i] as num?)?.toDouble() ?? 0,
        rainMm: rain,
        windKph: dayWind,
        weatherCode: dayCode,
        safetyScore: _score(
          // A forecast has no "raining right now" reading.
          precip: 0,
          dailyRain: rain,
          wind: dayWind,
          code: dayCode,
          difficulty: difficulty,
        ),
      ));
    }

    final todayRain = forecast.isEmpty ? 0.0 : forecast.first.rainMm;

    return TrailConditions(
      temperatureC: temp,
      precipitationMm: precip,
      dailyRainMm: todayRain,
      windKph: wind,
      weatherCode: code,
      safetyScore: _score(
        precip: precip,
        dailyRain: todayRain,
        wind: wind,
        code: code,
        difficulty: difficulty,
      ),
      forecast: forecast,
    );
  }

  /// WMO weather codes, grouped into plain language.
  static String describe(int code) {
    if (code == 0) return "Clear";
    if (code <= 2) return "Partly cloudy";
    if (code == 3) return "Overcast";
    if (code <= 48) return "Foggy";
    if (code <= 57) return "Drizzle";
    if (code <= 65) return "Rain";
    if (code <= 77) return "Snow";
    if (code <= 82) return "Rain showers";
    if (code <= 86) return "Snow showers";
    return "Thunderstorm";
  }

  /// Starts at 100 and deducts for each hazard. Harder trails lose more
  /// for the same weather, because bad conditions compound on rough ground.
  static int _score({
    required double precip,
    required double dailyRain,
    required double wind,
    required int code,
    required String difficulty,
  }) {
    var score = 100.0;

    if (precip > 0) score -= (precip * 6).clamp(0, 30);

    if (dailyRain >= 30) {
      score -= 30;
    } else if (dailyRain >= 15) {
      score -= 20;
    } else if (dailyRain >= 5) {
      score -= 10;
    }

    if (wind >= 50) {
      score -= 25;
    } else if (wind >= 30) {
      score -= 12;
    } else if (wind >= 20) {
      score -= 5;
    }

    if (code >= 95) {
      score -= 35; // thunderstorm
    } else if (code >= 80) {
      score -= 15;
    } else if (code >= 45 && code <= 48) {
      score -= 10; // fog hides the trail
    }

    final penaltyScale = switch (difficulty) {
      "Advanced" => 1.3,
      "Beginner" => 0.7,
      _ => 1.0,
    };

    final deducted = (100 - score) * penaltyScale;
    return (100 - deducted).clamp(5, 100).round();
  }
}










