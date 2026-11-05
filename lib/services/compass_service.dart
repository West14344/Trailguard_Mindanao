import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// One compass reading, already smoothed.
class CompassReading {
  /// 0-360, measured clockwise from magnetic north.
  final double headingDegrees;

  /// Total magnetic field strength in microtesla. Earth's field is roughly
  /// 25-65 uT, so a wild number means something nearby is magnetic.
  final double fieldStrength;

  /// False when the field strength is implausible, which usually means the
  /// sensor needs calibrating or a magnet / speaker / car is interfering.
  final bool trustworthy;

  const CompassReading({
    required this.headingDegrees,
    required this.fieldStrength,
    required this.trustworthy,
  });

  String get cardinal {
    const List<String> names = <String>[
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW',
    ];
    final double d = (headingDegrees % 360 + 360) % 360;
    return names[((d / 22.5) + 0.5).floor() % 16];
  }
}

/// A tilt-compensated magnetic compass built from the raw accelerometer and
/// magnetometer.
///
/// This is entirely offline. No network, no GPS, no runtime permission - it
/// reads the phone's own sensors, exactly like the hardware compass app does.
///
/// The maths is the same rotation-matrix method Android's SensorManager uses:
/// the magnetic vector is crossed with gravity to find east, east is crossed
/// with gravity to find north, and the heading falls out of those two.
class CompassService {
  final StreamController<CompassReading> _out =
      StreamController<CompassReading>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  List<double>? _acc;
  List<double>? _mag;

  // Smoothing is done on the sine and cosine so that the needle does not
  // spin the long way round when it crosses north.
  double _smoothSin = 0;
  double _smoothCos = 0;
  bool _primed = false;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  Stream<CompassReading> get readings => _out.stream;

  /// True once at least one usable reading has been produced.
  bool get hasReading => _primed;

  void start() {
    _accSub ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((AccelerometerEvent e) {
      _acc = <double>[e.x, e.y, e.z];
      _emit();
    }, onError: (Object _) {});

    _magSub ??= magnetometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((MagnetometerEvent e) {
      _mag = <double>[e.x, e.y, e.z];
      _emit();
    }, onError: (Object _) {});
  }

  Future<void> dispose() async {
    await _accSub?.cancel();
    await _magSub?.cancel();
    _accSub = null;
    _magSub = null;
    await _out.close();
  }

  void _emit() {
    final List<double>? acc = _acc;
    final List<double>? mag = _mag;
    if (acc == null || mag == null) return;

    // Throttle to about 15 updates a second. The sensors fire far faster
    // than the screen needs and rebuilding that often just burns battery.
    final DateTime now = DateTime.now();
    if (now.difference(_lastEmit).inMilliseconds < 66) return;

    final double ax = acc[0];
    final double ay = acc[1];
    final double az = acc[2];
    final double ex = mag[0];
    final double ey = mag[1];
    final double ez = mag[2];

    // East = magnetic x gravity
    double hx = ey * az - ez * ay;
    double hy = ez * ax - ex * az;
    double hz = ex * ay - ey * ax;

    final double normH = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (normH < 0.1) return; // phone is tilted straight at the field
    hx /= normH;
    hy /= normH;
    hz /= normH;

    final double normA = math.sqrt(ax * ax + ay * ay + az * az);
    if (normA < 0.1) return;
    final double nax = ax / normA;
    final double naz = az / normA;

    // Only the y component of north is needed for the heading.
    final double northY = naz * hx - nax * hz;

    double deg = math.atan2(hy, northY) * 180 / math.pi;
    deg = (deg + 360) % 360;

    final double rad = deg * math.pi / 180;
    if (!_primed) {
      _smoothSin = math.sin(rad);
      _smoothCos = math.cos(rad);
      _primed = true;
    } else {
      const double alpha = 0.18;
      _smoothSin += alpha * (math.sin(rad) - _smoothSin);
      _smoothCos += alpha * (math.cos(rad) - _smoothCos);
    }

    final double smoothed =
        (math.atan2(_smoothSin, _smoothCos) * 180 / math.pi + 360) % 360;

    final double field = math.sqrt(ex * ex + ey * ey + ez * ez);

    _lastEmit = now;
    if (_out.isClosed) return;
    _out.add(CompassReading(
      headingDegrees: smoothed,
      fieldStrength: field,
      trustworthy: field >= 20 && field <= 75,
    ));
  }
}