import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/breadcrumb_trail.dart';
import '../theme/app_theme.dart';

class BacktrackScreen extends StatefulWidget {
  const BacktrackScreen({super.key});

  @override
  State<BacktrackScreen> createState() => _BacktrackScreenState();
}

class _BacktrackScreenState extends State<BacktrackScreen> {
  static const Color _homeLine = Color(0xFFE8833A);

  final MapController _map = MapController();
  StreamSubscription<Position>? _sub;
  Position? _me;
  bool _compass = false;
  bool _follow = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _listen() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _error =
              'Location is off, so backtrack cannot show where you are.');
        }
        return;
      }

      _me = await Geolocator.getLastKnownPosition();
      if (mounted) setState(() {});

      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((Position p) {
        if (BreadcrumbTrail.isRecording) BreadcrumbTrail.record(p);
        if (!mounted) return;
        setState(() => _me = p);
        if (_follow) {
          _map.move(LatLng(p.latitude, p.longitude), _map.camera.zoom);
        }
      }, onError: (Object _) {});
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not read your position.');
      }
    }
  }

  void _recenter() {
    final Position? me = _me;
    if (me == null) return;
    setState(() => _follow = true);
    _map.move(LatLng(me.latitude, me.longitude), 16);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: BreadcrumbTrail.revision,
      builder: (BuildContext context, int _, Widget? _) {
        final Position? me = _me;
        final BacktrackInfo? info = me == null
            ? null
            : BreadcrumbTrail.backtrackFrom(me.latitude, me.longitude);

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            backgroundColor: AppColors.paper,
            foregroundColor: AppColors.ink,
            elevation: 0,
            title: Text(
              'Backtrack',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: <Widget>[
              IconButton(
                tooltip: _compass ? 'Map view' : 'Compass view',
                icon: Icon(
                  _compass ? Icons.map_outlined : Icons.explore_outlined,
                  color: AppColors.ink,
                ),
                onPressed: () => setState(() => _compass = !_compass),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.ink),
                onSelected: (String v) async {
                  if (v != 'clear') return;
                  await BreadcrumbTrail.clear();
                  if (mounted) setState(() {});
                },
                itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: Text('Clear breadcrumbs'),
                  ),
                ],
              ),
            ],
          ),
          body: BreadcrumbTrail.pointCount == 0
              ? _empty()
              : Column(
                  children: <Widget>[
                    _summary(info),
                    Expanded(
                      child: _compass ? _compassView(info) : _mapView(info),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.timeline_rounded, size: 64, color: AppColors.pine),
            const SizedBox(height: 18),
            Text(
              'No breadcrumbs yet',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ??
                  'TrailGuard drops a breadcrumb every 15 metres once you '
                      'start a hike. Come back here and it will show you the '
                      'exact way you came, even with no signal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink, height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentFill,
                foregroundColor: AppColors.onAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start recording now'),
              onPressed: () async {
                final bool ok = await BreadcrumbTrail.begin();
                if (!mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Turn on location to record breadcrumbs.',
                      ),
                      backgroundColor: AppColors.pine,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(BacktrackInfo? info) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.undo_rounded, size: 18, color: AppColors.pine),
              const SizedBox(width: 8),
              Text(
                'Back to start',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              _chip(
                BreadcrumbTrail.isRecording ? 'Recording' : 'Trail saved',
                BreadcrumbTrail.isRecording,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            info == null
                ? 'Finding you...'
                : BreadcrumbTrail.formatDistance(info.alongTrailMetres),
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'following the path you walked',
            style: TextStyle(color: AppColors.ink, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _stat(
                'Straight line',
                info == null
                    ? '--'
                    : BreadcrumbTrail.formatDistance(info.straightLineMetres),
              ),
              _stat(
                'Direction',
                info == null
                    ? '--'
                    : '${info.bearingDegrees.round()}\u00B0 ${info.cardinal}',
              ),
              _stat('Breadcrumbs', '${BreadcrumbTrail.pointCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool live) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.onAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.onAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(color: AppColors.ink, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapView(BacktrackInfo? info) {
    final List<LatLng> walked = BreadcrumbTrail.path;
    final LatLng startLL = BreadcrumbTrail.startPoint!.latLng;
    final Position? me = _me;
    final LatLng center = me != null
        ? LatLng(me.latitude, me.longitude)
        : (walked.isNotEmpty ? walked.last : startLL);

    return Stack(
      children: <Widget>[
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16,
            onPositionChanged: (dynamic _, bool hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.trailguard_ai',
            ),
            if (walked.length >= 2)
              PolylineLayer<Object>(
                polylines: <Polyline<Object>>[
                  Polyline<Object>(
                    points: walked,
                    color: AppColors.pine,
                    strokeWidth: 6,
                  ),
                ],
              ),
            if (info != null && info.returnPath.length >= 2)
              PolylineLayer<Object>(
                polylines: <Polyline<Object>>[
                  Polyline<Object>(
                    points: info.returnPath,
                    color: _homeLine,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  point: startLL,
                  width: 38,
                  height: 38,
                  child: _pin(Icons.flag_rounded),
                ),
                if (me != null)
                  Marker(
                    point: LatLng(me.latitude, me.longitude),
                    width: 30,
                    height: 30,
                    child: _youDot(),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                _legendLine(AppColors.pine),
                const SizedBox(width: 6),
                Text(
                  'Where you walked',
                  style: TextStyle(color: AppColors.ink, fontSize: 11.5),
                ),
                const SizedBox(width: 14),
                _legendLine(_homeLine),
                const SizedBox(width: 6),
                Text(
                  'Way back',
                  style: TextStyle(color: AppColors.ink, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 14,
          child: FloatingActionButton.small(
            heroTag: 'backtrack_recenter',
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.ink,
            onPressed: _recenter,
            child: Icon(
              _follow ? Icons.my_location : Icons.location_searching,
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendLine(Color color) {
    return Container(
      width: 16,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _pin(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentFill,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: AppColors.onAccent),
    );
  }

  Widget _youDot() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2F6FD0),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }

  Widget _compassView(BacktrackInfo? info) {
    if (info == null) {
      return Center(
        child: Text(
          _error ?? 'Waiting for GPS...',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.ink),
        ),
      );
    }

    final double heading = _me?.heading ?? -1;
    final double speed = _me?.speed ?? 0;
    final bool deviceRelative = heading >= 0 && speed > 0.6;
    final double shown =
        deviceRelative ? info.bearingDegrees - heading : info.bearingDegrees;
    final double radians = shown * math.pi / 180;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: _rosePoint('N'),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _rosePoint('S'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _rosePoint('E'),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _rosePoint('W'),
                ),
                Transform.rotate(
                  angle: radians,
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 128,
                    color: AppColors.pine,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            BreadcrumbTrail.formatDistance(info.alongTrailMetres),
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'back to where you started',
            style: TextStyle(color: AppColors.ink, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            'Head ${info.bearingDegrees.round()}\u00B0 ${info.cardinal}',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.wifi_off_rounded,
                  size: 18,
                  color: AppColors.pine,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    deviceRelative
                        ? 'The arrow points the way. Keep walking so it stays '
                            'accurate. This view needs no internet.'
                        : 'The arrow is north-up: line the top of your phone '
                            'up with north, then follow it. Start walking and '
                            'it points directly. This view needs no internet.',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rosePoint(String label) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}