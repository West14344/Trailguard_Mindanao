import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// One recorded GPS crumb.
class BreadcrumbPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime time;

  BreadcrumbPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.time,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

/// The answer to "how do I get back?" computed from a position.
class BacktrackInfo {
  /// Distance home following the path you walked.
  final double alongTrailMetres;

  /// Straight-line distance to the start point.
  final double straightLineMetres;

  /// Compass bearing (0-360, 0 = north) toward the next waypoint home.
  final double bearingDegrees;

  /// Your position, then every crumb from the nearest one back to the start.
  final List<LatLng> returnPath;

  /// Index of the crumb closest to you.
  final int nearestIndex;

  BacktrackInfo({
    required this.alongTrailMetres,
    required this.straightLineMetres,
    required this.bearingDegrees,
    required this.returnPath,
    required this.nearestIndex,
  });

  String get cardinal => BreadcrumbTrail.cardinalFor(bearingDegrees);
}

/// Records where you have walked and works out the way back.
///
/// Everything here is on-device. No network, no Firestore, no permissions
/// beyond the location access the app already asks for.
class BreadcrumbTrail {
  BreadcrumbTrail._();

  /// Ignore moves smaller than this so GPS jitter does not fill the list.
  static const double minGapMetres = 15;

  /// Ignore fixes worse than this (metres of accuracy).
  static const double worstAccuracyMetres = 50;

  /// Safety cap. Past this the trail is thinned instead of grown.
  static const int maxPoints = 4000;

  static final List<BreadcrumbPoint> _points = <BreadcrumbPoint>[];
  static final List<double> _cumulative = <double>[0];
  static StreamSubscription<Position>? _sub;
  static bool _recording = false;

  /// Bump this and any ValueListenableBuilder watching it rebuilds.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool get isRecording => _recording;
  static int get pointCount => _points.length;
  static bool get hasTrail => _points.length >= 2;

  static List<BreadcrumbPoint> get points =>
      List<BreadcrumbPoint>.unmodifiable(_points);

  static List<LatLng> get path =>
      _points.map((BreadcrumbPoint p) => p.latLng).toList();

  static BreadcrumbPoint? get startPoint =>
      _points.isEmpty ? null : _points.first;

  static BreadcrumbPoint? get lastPoint =>
      _points.isEmpty ? null : _points.last;

  /// Distance actually walked along the recorded path.
  static double get walkedMetres => _cumulative.isEmpty ? 0 : _cumulative.last;
  static double get walkedKm => walkedMetres / 1000;

  // ---------------------------------------------------------------- recording

  /// Starts recording. Returns false if location is off or denied.
  static Future<bool> begin({bool fresh = true}) async {
    if (_recording) return true;

    if (!await Geolocator.isLocationServiceEnabled()) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    if (fresh) _resetPoints();
    _recording = true;
    revision.value++;

    try {
      final Position first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      record(first);
    } catch (_) {
      // No first fix yet. The stream below will supply one.
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 8,
      ),
    ).listen(record, onError: (Object _) {});

    return true;
  }

  /// Stops recording but KEEPS the trail, so backtrack still works
  /// after the hike is finished.
  static Future<void> end() async {
    _recording = false;
    await _sub?.cancel();
    _sub = null;
    revision.value++;
  }

  /// Stops recording and throws the trail away.
  static Future<void> clear() async {
    await end();
    _resetPoints();
    revision.value++;
  }

  /// Feed a position in. Safe to call from anywhere - duplicates and
  /// jittery fixes are filtered out here.
  static void record(Position p) {
    if (_points.isNotEmpty && p.accuracy > worstAccuracyMetres) return;

    if (_points.isNotEmpty) {
      final BreadcrumbPoint prev = _points.last;
      final double gap = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        p.latitude,
        p.longitude,
      );
      if (gap < minGapMetres) return;
      _cumulative.add(_cumulative.last + gap);
    }

    _points.add(BreadcrumbPoint(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      time: DateTime.now(),
    ));

    if (_points.length > maxPoints) _thin();
    revision.value++;
  }

  // ---------------------------------------------------------------- backtrack

  /// Works out the way home from where you are now.
  static BacktrackInfo? backtrackFrom(double lat, double lng) {
    if (_points.isEmpty) return null;

    int nearest = 0;
    double best = double.infinity;
    for (int i = 0; i < _points.length; i++) {
      final double d = Geolocator.distanceBetween(
        lat,
        lng,
        _points[i].latitude,
        _points[i].longitude,
      );
      if (d < best) {
        best = d;
        nearest = i;
      }
    }

    final double along = best + _cumulative[nearest];

    final BreadcrumbPoint first = _points.first;
    final double straight = Geolocator.distanceBetween(
      lat,
      lng,
      first.latitude,
      first.longitude,
    );

    // Aim at a crumb roughly 25 m further back along the trail rather than
    // at the start itself, so you follow the path instead of cutting across
    // whatever is in between.
    int aim = nearest;
    while (aim > 0 && (_cumulative[nearest] - _cumulative[aim]) < 25) {
      aim--;
    }
    final BreadcrumbPoint target = _points[aim];

    final double bearing = _bearing(
      lat,
      lng,
      target.latitude,
      target.longitude,
    );

    final List<LatLng> back = <LatLng>[LatLng(lat, lng)];
    for (int i = nearest; i >= 0; i--) {
      back.add(_points[i].latLng);
    }

    return BacktrackInfo(
      alongTrailMetres: along,
      straightLineMetres: straight,
      bearingDegrees: bearing,
      returnPath: back,
      nearestIndex: nearest,
    );
  }

  // ------------------------------------------------------------------ helpers

  static String formatDistance(double metres) {
    if (metres < 950) return '${metres.round()} m';
    if (metres < 9500) return '${(metres / 1000).toStringAsFixed(2)} km';
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }

  static String cardinalFor(double degrees) {
    const List<String> names = <String>[
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW',
    ];
    final double d = (degrees % 360 + 360) % 360;
    return names[((d / 22.5) + 0.5).floor() % 16];
  }

  static double _bearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double p1 = lat1 * math.pi / 180;
    final double p2 = lat2 * math.pi / 180;
    final double dl = (lon2 - lon1) * math.pi / 180;
    final double y = math.sin(dl) * math.cos(p2);
    final double x =
        math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
    final double deg = math.atan2(y, x) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  static void _resetPoints() {
    _points.clear();
    _cumulative
      ..clear()
      ..add(0);
  }

  /// Drops every second crumb when the cap is hit, keeping the shape.
  static void _thin() {
    final List<BreadcrumbPoint> kept = <BreadcrumbPoint>[];
    for (int i = 0; i < _points.length; i++) {
      if (i.isEven || i == _points.length - 1) kept.add(_points[i]);
    }
    _points
      ..clear()
      ..addAll(kept);
    _rebuildCumulative();
  }

  static void _rebuildCumulative() {
    _cumulative
      ..clear()
      ..add(0);
    for (int i = 1; i < _points.length; i++) {
      _cumulative.add(_cumulative.last +
          Geolocator.distanceBetween(
            _points[i - 1].latitude,
            _points[i - 1].longitude,
            _points[i].latitude,
            _points[i].longitude,
          ));
    }
  }
}