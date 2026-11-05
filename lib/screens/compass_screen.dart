import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../services/breadcrumb_trail.dart';
import '../services/compass_service.dart';
import '../theme/app_theme.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  static const Color _needleRed = Color(0xFFD9452F);
  static const Color _homeOrange = Color(0xFFE8833A);

  final CompassService _compass = CompassService();
  StreamSubscription<CompassReading>? _readingSub;
  StreamSubscription<Position>? _posSub;
  Timer? _sensorTimeout;

  CompassReading? _reading;
  Position? _me;
  bool _noSensor = false;

  @override
  void initState() {
    super.initState();
    _compass.start();
    _readingSub = _compass.readings.listen((CompassReading r) {
      if (!mounted) return;
      setState(() {
        _reading = r;
        _noSensor = false;
      });
    });

    // If nothing arrives in three seconds there is no magnetometer.
    _sensorTimeout = Timer(const Duration(seconds: 3), () {
      if (!mounted || _reading != null) return;
      setState(() => _noSensor = true);
    });

    _watchPosition();
  }

  @override
  void dispose() {
    _sensorTimeout?.cancel();
    _readingSub?.cancel();
    _posSub?.cancel();
    _compass.dispose();
    super.dispose();
  }

  /// GPS is optional here. Without it the compass still works; you just lose
  /// the coordinates readout and the marker pointing back to the trailhead.
  Future<void> _watchPosition() async {
    try {
      final LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      _me = await Geolocator.getLastKnownPosition();
      if (mounted) setState(() {});
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position p) {
        if (!mounted) return;
        setState(() => _me = p);
      }, onError: (Object _) {});
    } catch (_) {
      // No position. The compass does not need one.
    }
  }

  @override
  Widget build(BuildContext context) {
    final CompassReading? r = _reading;
    final Position? me = _me;
    final BacktrackInfo? home = (me == null || !BreadcrumbTrail.hasTrail)
        ? null
        : BreadcrumbTrail.backtrackFrom(me.latitude, me.longitude);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(
          'Compass',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _noSensor
          ? _noSensorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                children: <Widget>[
                  _dial(r, home),
                  const SizedBox(height: 24),
                  if (r != null && !r.trustworthy) _calibrationBanner(),
                  if (r != null && !r.trustworthy) const SizedBox(height: 12),
                  if (home != null) _homeCard(home),
                  if (home != null) const SizedBox(height: 12),
                  _positionCard(me),
                  const SizedBox(height: 12),
                  _offlineNote(),
                ],
              ),
            ),
    );
  }

  Widget _dial(CompassReading? r, BacktrackInfo? home) {
    final double heading = r?.headingDegrees ?? 0;

    return SizedBox(
      width: 290,
      height: 290,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
          ),

          // The dial itself turns, so north on the card always points at
          // real north. That is how a physical compass behaves.
          Transform.rotate(
            angle: -heading * math.pi / 180,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CustomPaint(
                  size: const Size(290, 290),
                  painter: _DialPainter(
                    tick: AppColors.ink,
                    label: AppColors.ink,
                    ring: AppColors.pine,
                    northColor: _needleRed,
                  ),
                ),
                if (home != null)
                  Transform.rotate(
                    angle: home.bearingDegrees * math.pi / 180,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _homeOrange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.card,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Fixed pointer: whatever sits under this is the way you are facing.
          Align(
            alignment: Alignment.topCenter,
            child: Icon(
              Icons.arrow_drop_down_rounded,
              size: 40,
              color: _needleRed,
            ),
          ),

          // Readout stays upright while the dial turns.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                r == null ? '--' : '${r.headingDegrees.round()}\u00B0',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                r == null ? 'reading sensors' : r.cardinal,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calibrationBanner() {
    return _card(
      icon: Icons.refresh_rounded,
      iconColor: _needleRed,
      child: Text(
        'Readings look off. Wave the phone in a figure-8 a few times, and '
        'move away from anything magnetic - speakers, car doors, metal rails.',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _homeCard(BacktrackInfo home) {
    return _card(
      icon: Icons.circle,
      iconColor: _homeOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Trailhead is ${BreadcrumbTrail.formatDistance(home.alongTrailMetres)} away',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'The orange dot on the dial is the way back, at '
            '${home.bearingDegrees.round()}\u00B0 ${home.cardinal}. '
            'Turn until it sits under the red pointer, then walk.',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionCard(Position? me) {
    if (me == null) {
      return _card(
        icon: Icons.location_off_outlined,
        iconColor: AppColors.pine,
        child: Text(
          'No GPS fix yet. The compass works without it.',
          style: TextStyle(color: AppColors.ink, fontSize: 12.5),
        ),
      );
    }

    final String coords =
        '${me.latitude.toStringAsFixed(5)}, ${me.longitude.toStringAsFixed(5)}';

    return _card(
      icon: Icons.my_location_rounded,
      iconColor: AppColors.pine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your coordinates',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  coords,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: AppColors.pine,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: coords));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Coordinates copied'),
                      backgroundColor: AppColors.pine,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          Text(
            'accurate to about ${me.accuracy.round()} m',
            style: TextStyle(color: AppColors.ink, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _offlineNote() {
    return _card(
      icon: Icons.wifi_off_rounded,
      iconColor: AppColors.pine,
      child: Text(
        'This compass reads your phone\u2019s own magnetic sensor. It needs no '
        'signal, no data and no map tiles, so it keeps working anywhere on '
        'the mountain.',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _noSensorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.explore_off_outlined,
              size: 64,
              color: AppColors.pine,
            ),
            const SizedBox(height: 18),
            Text(
              'No compass sensor',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This device has no magnetometer, so the heading cannot be '
              'measured. Most emulators do not have one - try it on a real '
              'phone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the compass face: ring, degree ticks and the four cardinal letters.
class _DialPainter extends CustomPainter {
  final Color tick;
  final Color label;
  final Color ring;
  final Color northColor;

  _DialPainter({
    required this.tick,
    required this.label,
    required this.ring,
    required this.northColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = math.min(size.width, size.height) / 2;

    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );

    for (int deg = 0; deg < 360; deg += 10) {
      final bool major = deg % 30 == 0;
      final double len = major ? 13 : 6;
      final double rad = (deg - 90) * math.pi / 180;
      final Offset outer =
          c + Offset(math.cos(rad) * (r - 4), math.sin(rad) * (r - 4));
      final Offset inner = c +
          Offset(math.cos(rad) * (r - 4 - len), math.sin(rad) * (r - 4 - len));
      canvas.drawLine(
        outer,
        inner,
        Paint()
          ..color = tick
          ..strokeWidth = major ? 2.4 : 1.1,
      );
    }

    const Map<int, String> marks = <int, String>{
      0: 'N',
      90: 'E',
      180: 'S',
      270: 'W',
    };

    marks.forEach((int deg, String text) {
      final bool isNorth = deg == 0;
      final double rad = (deg - 90) * math.pi / 180;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: isNorth ? northColor : label,
            fontSize: isNorth ? 22 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset pos =
          c + Offset(math.cos(rad) * (r - 38), math.sin(rad) * (r - 38));
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.tick != tick ||
      old.label != label ||
      old.ring != ring ||
      old.northColor != northColor;
}