import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";

import "../data/hike_records.dart";
import "../services/breadcrumb_trail.dart";
import "../theme/app_theme.dart";

/// The route drawing itself as you walk it.
///
/// Reads the position ActiveHike already publishes on every fix rather
/// than opening a second GPS stream, so this costs no extra battery.
class LiveTrackMap extends StatefulWidget {
  final double height;
  const LiveTrackMap({super.key, this.height = 170});

  @override
  State<LiveTrackMap> createState() => _LiveTrackMapState();
}

class _LiveTrackMapState extends State<LiveTrackMap> {
  final MapController _map = MapController();
  Timer? _poll;
  bool _ready = false;
  bool _follow = true;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _lat = ActiveHike.latitude;
    _lng = ActiveHike.longitude;
    // One second is plenty: fixes arrive about that often, and the trail
    // itself only gains a point every 15 metres.
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final double? lat = ActiveHike.latitude;
    final double? lng = ActiveHike.longitude;
    final bool moved = lat != _lat || lng != _lng;

    setState(() {
      _lat = lat;
      _lng = lng;
    });

    if (moved && _follow && _ready && lat != null && lng != null) {
      _map.move(LatLng(lat, lng), _map.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> walked = BreadcrumbTrail.path;
    final LatLng? me =
        (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null;
    final LatLng? centre = me ?? (walked.isNotEmpty ? walked.last : null);

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: centre == null
            ? Container(
                color: AppColors.fill,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      "Waiting for a GPS fix. Your route appears here once "
                      "the first position arrives.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              )
            : Stack(
                children: <Widget>[
                  FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: centre,
                      initialZoom: 16,
                      onMapReady: () {
                        if (!_ready) _ready = true;
                      },
                      // Panning by hand stops the map chasing you, so it
                      // does not fight someone checking what is ahead.
                      onPointerDown: (_, _) {
                        if (_follow) setState(() => _follow = false);
                      },
                    ),
                    children: <Widget>[
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: "com.example.trailguard_ai",
                      ),
                      if (walked.length >= 2)
                        PolylineLayer<Object>(
                          polylines: <Polyline<Object>>[
                            Polyline<Object>(
                              points: walked,
                              strokeWidth: 4,
                              color: AppColors.forest,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: <Marker>[
                          if (walked.isNotEmpty)
                            Marker(
                              point: walked.first,
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.blaze,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                ),
                              ),
                            ),
                          if (me != null)
                            Marker(
                              point: me,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.pine,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Breadcrumb count, which doubles as the signal that
                  // recording is actually alive.
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        walked.isEmpty
                            ? "No breadcrumbs yet"
                            : "${walked.length} breadcrumbs - "
                                "${BreadcrumbTrail.formatDistance(BreadcrumbTrail.walkedMetres)}",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: _follow ? AppColors.forest : AppColors.card,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          setState(() => _follow = true);
                          if (me != null && _ready) _map.move(me, 16);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(
                            Icons.my_location_rounded,
                            size: 18,
                            color: _follow ? Colors.white : AppColors.forest,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}