import "dart:async";

import "package:geolocator/geolocator.dart";

/// Wraps geolocator so screens deal with one small API instead of the
/// permission dance.
class LocationService {
  /// Asks for permission if needed. Returns null when granted, or a
  /// message explaining why location is unavailable.
  static Future<String?> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return "Location is switched off on this device. Turn it on to track "
          "your hike.";
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return "Location permission is needed to track distance and share "
          "your position in an emergency.";
    }
    if (permission == LocationPermission.deniedForever) {
      return "Location is blocked for this app. Enable it in your phone "
          "settings to use tracking and SOS.";
    }
    return null;
  }

  static Future<bool> get hasPermission async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  /// One reading, for SOS and hazard reports.
  static Future<Position?> currentPosition() async {
    if (await ensurePermission() != null) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      // Fall back to the last known fix rather than failing outright.
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Continuous updates while hiking. Fires every 5 metres so short pauses
  /// do not add phantom distance from GPS jitter.
  static Stream<Position> track() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    );
  }

  /// Metres between two points, using the same maths as latlong2.
  static double metresBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  static Future<void> openSettings() => Geolocator.openAppSettings();
}










