import 'dart:convert';
import 'package:http/http.dart' as http;

/// Live conditions plus a safety score derived from them.
class TrailConditions {
  final double temperatureC;
  final double precipitationMm;
  final double dailyRainMm;
  final double windKph;
  final int weatherCode;
  final int safetyScore;

  const TrailConditions({
    required this.temperatureC,
    required this.precipitationMm,
    required this.dailyRainMm,
    required this.windKph,
    required this.weatherCode,
    required this.safetyScore,
  });

  String get summary => '${describe(weatherCode)}, ${temperatureC.round()}°C';

  String get rainfallRisk {
    if (dailyRainMm >= 20) return 'High';
    if (dailyRainMm >= 5) return 'Moderate';
    return 'Low';
  }

  String get windSummary => '${windKph.round()} km/h';

  /// WMO weather codes, grouped into plain language.
  static String describe(int code) {
    if (code == 0) return 'Clear';
    if (code <= 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 65) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    return 'Thunderstorm';
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
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,precipitation,weather_code,wind_speed_10m'
      '&daily=precipitation_sum'
      '&timezone=auto&forecast_days=1',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Weather service returned ${response.statusCode}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final current = body['current'] as Map<String, dynamic>;
    final daily = body['daily'] as Map<String, dynamic>;

    final temp = (current['temperature_2m'] as num).toDouble();
    final precip = (current['precipitation'] as num?)?.toDouble() ?? 0;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;
    final code = (current['weather_code'] as num).toInt();
    final dailyRain =
        ((daily['precipitation_sum'] as List).first as num?)?.toDouble() ?? 0;

    return TrailConditions(
      temperatureC: temp,
      precipitationMm: precip,
      dailyRainMm: dailyRain,
      windKph: wind,
      weatherCode: code,
      safetyScore: _score(
        precip: precip,
        dailyRain: dailyRain,
        wind: wind,
        code: code,
        difficulty: difficulty,
      ),
    );
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
      'Advanced' => 1.3,
      'Beginner' => 0.7,
      _ => 1.0,
    };

    final deducted = (100 - score) * penaltyScale;
    return (100 - deducted).clamp(5, 100).round();
  }
}