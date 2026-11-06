import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/hike_records.dart';
import '../services/breadcrumb_trail.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/backtrack_button.dart';
import '../widgets/live_track_map.dart';

/// Live tracking view. Replaces the dashboard while a hike is running.
///
/// Distance comes from the GPS, not from a timer: a phone sitting on a rock
/// adds nothing. Three gates keep drift out of the total - the fix has to be
/// accurate enough to trust, the step has to be bigger than the error radius,
/// and the implied speed has to be humanly possible.
class HikeTrackingView extends StatefulWidget {
  final VoidCallback onFinished;
  const HikeTrackingView({super.key, required this.onFinished});

  @override
  State<HikeTrackingView> createState() => _HikeTrackingViewState();
}

class _HikeTrackingViewState extends State<HikeTrackingView> {
  /// Fixes sloppier than this say nothing useful about movement.
  static const double _worstAccuracyM = 50;

  /// Never count a step smaller than this, however good the fix claims to be.
  static const double _minStepM = 8;

  /// A "step" faster than this is a GPS jump, not a hiker.
  static const double _maxSpeedMs = 6.0;

  /// No real movement for this long and the clock stops too.
  static const int _autoPauseAfterS = 45;

  Timer? _ticker;
  StreamSubscription<Position>? _gps;

  Position? _lastAccepted;
  DateTime _lastAcceptedAt = DateTime.now();
  DateTime _lastMovementAt = DateTime.now();

  double? _accuracyM;
  String? _gpsError;
  bool _waitingForFix = true;

  @override
  void initState() {
    super.initState();
    _startGps();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _gps?.cancel();
    super.dispose();
  }

  Future<void> _startGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          _gpsError = 'Location is switched off, so distance cannot be '
              'measured. Turn it on and restart the hike.';
          _waitingForFix = false;
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _gpsError = 'Location permission is off, so distance cannot be '
              'measured.';
          _waitingForFix = false;
        });
        return;
      }

      _gps = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen(_onPosition, onError: (Object _) {});
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _gpsError = 'Could not start GPS tracking. $err';
        _waitingForFix = false;
      });
    }
  }

  void _onPosition(Position p) {
    if (!mounted || !ActiveHike.isActive) return;

    // Always publish the latest fix, even one too rough to measure with.
    // SOS, hazard reports and the group map all read these.
    ActiveHike.latitude = p.latitude;
    ActiveHike.longitude = p.longitude;
    ActiveHike.accuracyM = p.accuracy;
    debugPrint("[GPS] fix acc=${p.accuracy.toStringAsFixed(1)}m "
        "speed=${p.speed.toStringAsFixed(2)}m/s");
    BreadcrumbTrail.record(p);

    if (_waitingForFix || _accuracyM != p.accuracy) {
      setState(() {
        _waitingForFix = false;
        _accuracyM = p.accuracy;
        _gpsError = null;
      });
    }

    // A manual pause means the hiker said they stopped. Keep the reference
    // point current so resuming does not bank the gap as one huge step.
    if (ActiveHike.isPaused) {
      _lastAccepted = p;
      _lastAcceptedAt = DateTime.now();
      return;
    }

    // The "moving" badge follows the receiver's own speed, which is
    // doppler-derived and reports motion long before enough
    // displacement has piled up to credit a step of distance.
    if (p.speed.isFinite && p.speed >= 0.6) {
      _lastMovementAt = DateTime.now();
      if (ActiveHike.isAutoPaused) {
        setState(() => ActiveHike.isAutoPaused = false);
      }
    }

    if (p.accuracy > _worstAccuracyM) {
      debugPrint("[GPS] dropped: accuracy "
          "${p.accuracy.toStringAsFixed(1)}m, limit $_worstAccuracyM m");
      return;
    }

    final Position? previous = _lastAccepted;
    if (previous == null) {
      _lastAccepted = p;
      _lastAcceptedAt = DateTime.now();
      return;
    }

    final double metres = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      p.latitude,
      p.longitude,
    );

    // Scale the threshold with the reported error. A fix good to 4 m can be
    // trusted over 8 m; a fix good to 20 m needs a bigger move to be real.
    final double threshold =
        math.min(20.0, math.max(_minStepM, p.accuracy * 0.5));
    if (metres < threshold) {
      debugPrint("[GPS] held: moved ${metres.toStringAsFixed(1)}m, "
          "need ${threshold.toStringAsFixed(1)}m");
      return;
    }

    final double seconds =
        DateTime.now().difference(_lastAcceptedAt).inMilliseconds / 1000;
    if (seconds <= 0) return;

    final double speed = metres / seconds;
    if (speed > _maxSpeedMs) {
      // A jump, not a walk. Re-anchor without crediting the distance.
      _lastAccepted = p;
      _lastAcceptedAt = DateTime.now();
      return;
    }

    setState(() {
      ActiveHike.distanceKm += metres / 1000;
      debugPrint("[GPS] credited ${metres.toStringAsFixed(1)}m "
          "-> ${ActiveHike.distanceKm.toStringAsFixed(3)}km");
      _lastAccepted = p;
      _lastAcceptedAt = DateTime.now();
      _lastMovementAt = DateTime.now();
      ActiveHike.isAutoPaused = false;
    });
  }

  void _tick() {
    if (!mounted || !ActiveHike.isActive) return;
    if (ActiveHike.isPaused) return;

    final int idle = DateTime.now().difference(_lastMovementAt).inSeconds;
    final bool autoPaused = idle >= _autoPauseAfterS;

    setState(() {
      ActiveHike.isAutoPaused = autoPaused;
      // Moving time means moving. Standing still does not count.
      if (!autoPaused) {
        ActiveHike.elapsed += const Duration(seconds: 1);
      }
    });
  }

  String get _pace {
    if (ActiveHike.distanceKm < 0.05) return '--:--';
    final minPerKm = ActiveHike.elapsed.inSeconds / 60 / ActiveHike.distanceKm;
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round().toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _gpsLabel {
    if (_gpsError != null) return _gpsError!;
    if (_waitingForFix) return 'Finding GPS. Distance starts once you move.';
    final a = _accuracyM;
    if (a == null) return 'GPS ready.';
    if (a > _worstAccuracyM) {
      return 'GPS accurate to ${a.round()} m - too rough to measure. '
          'Move to open sky.';
    }
    return 'GPS accurate to ${a.round()} m.';
  }

  Future<void> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Finish this hike?'),
        content: Text(
          'You have covered ${ActiveHike.distanceKm.toStringAsFixed(2)} km '
          'in ${formatDuration(ActiveHike.elapsed)}. This will be saved to '
          'your achievements.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: Text('Keep hiking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.forest),
            child: const Text('Finish and save'),
          ),
        ],
      ),
    );

    if (stop != true || !mounted) return;

    final record = ActiveHike.finish();
    _ticker?.cancel();
    _gps?.cancel();
    BreadcrumbTrail.end();
    widget.onFinished();

    if (record != null && mounted) {
      _showSummary(record);
    }
  }

  void _showSummary(HikeRecord record) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 38, color: AppColors.forest),
              ),
              const SizedBox(height: 18),
              Text('Hike saved',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(record.mountainName,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: 'Distance',
                      value: '${record.distanceKm.toStringAsFixed(2)} km',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryStat(
                      label: 'Moving time',
                      value: formatDuration(record.movingTime),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trail = ActiveHike.trail;
    if (trail == null) return const SizedBox.shrink();

    final paused = ActiveHike.isPaused;
    final autoPaused = ActiveHike.isAutoPaused;
    final problem = _gpsError != null ||
        _waitingForFix ||
        (_accuracyM != null && _accuracyM! > _worstAccuracyM);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.terrain_rounded,
                    size: 18, color: AppColors.forest),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    trail.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(paused: paused, autoPaused: autoPaused),
              ],
            ),

            const Spacer(flex: 2),

            // Time is the anchor: biggest thing on the screen, glanceable
            // at arm's length while walking.
            Text(
              formatDuration(ActiveHike.elapsed),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 68,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -3,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.pine,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'MOVING TIME',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),

            SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    value: ActiveHike.distanceKm.toStringAsFixed(2),
                    unit: 'km',
                    label: 'Distance',
                  ),
                ),
                Container(width: 1, height: 54, color: AppColors.line),
                Expanded(
                  child: _BigStat(
                    value: _pace,
                    unit: '/km',
                    label: 'Pace',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  problem
                      ? Icons.gps_not_fixed_rounded
                      : Icons.gps_fixed_rounded,
                  size: 15,
                  color: problem ? AppColors.blaze : AppColors.forest,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    _gpsLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: problem ? AppColors.blaze : AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 3),

            const LiveTrackMap(height: 170),
            const SizedBox(height: 14),

            const BacktrackButton(),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: () => setState(
                          () => ActiveHike.isPaused = !ActiveHike.isPaused),
                      icon: Icon(
                          paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          size: 22),
                      label: Text(paused ? 'Resume' : 'Pause'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            paused ? AppColors.forest : AppColors.mist,
                        foregroundColor:
                            paused ? Colors.white : AppColors.pine,
                        elevation: 0,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.pill),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: _confirmStop,
                      icon: Icon(Icons.stop_rounded, size: 22),
                      label: Text('Stop'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.alertFill,
                        foregroundColor: AppColors.onAlert,
                        elevation: 0,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Stopping saves this hike to your achievements.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool paused;
  final bool autoPaused;

  const _StatusChip({required this.paused, required this.autoPaused});

  @override
  Widget build(BuildContext context) {
    final (label, color) = paused
        ? ('Paused', AppColors.inkSoft)
        : autoPaused
            ? ('Not moving', AppColors.blaze)
            : ('Moving', AppColors.forest);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _BigStat({
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.ink,
              ),
            ),
            SizedBox(width: 4),
            Text(unit,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
