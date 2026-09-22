import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../data/hike_records.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

/// Live tracking view. Replaces the dashboard while a hike is running.
class HikeTrackingView extends StatefulWidget {
  final VoidCallback onFinished;
  const HikeTrackingView({super.key, required this.onFinished});

  @override
  State<HikeTrackingView> createState() => _HikeTrackingViewState();
}

class _HikeTrackingViewState extends State<HikeTrackingView> {
  Timer? _ticker;
  final _random = math.Random();

  /// Simulated walking pace. Replace this block with a geolocator position
  /// stream and the rest of the screen works unchanged.
  double _speedKph = 4.2;
  int _secondsUntilRest = 50;
  int _restSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || !ActiveHike.isActive) return;

    // A manual pause freezes everything until the hiker resumes.
    if (ActiveHike.isPaused) return;

    setState(() {
      if (_restSecondsLeft > 0) {
        // No movement detected, so the clock and distance both stop.
        _restSecondsLeft--;
        ActiveHike.isAutoPaused = true;
        if (_restSecondsLeft == 0) {
          _secondsUntilRest = 45 + _random.nextInt(40);
        }
        return;
      }

      ActiveHike.isAutoPaused = false;

      // Pace drifts a little so the numbers do not look mechanical.
      _speedKph = (_speedKph + (_random.nextDouble() - 0.5) * 0.4)
          .clamp(3.0, 5.4);

      ActiveHike.elapsed += const Duration(seconds: 1);
      ActiveHike.distanceKm += _speedKph / 3600;

      _secondsUntilRest--;
      if (_secondsUntilRest <= 0) {
        _restSecondsLeft = 8 + _random.nextInt(8);
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

  Future<void> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Finish this hike?'),
        content: Text(
          'You have covered ${ActiveHike.distanceKm.toStringAsFixed(2)} km '
          'in ${formatDuration(ActiveHike.elapsed)}. This will be saved to '
          'your achievements.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: const Text('Keep hiking'),
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
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
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

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.terrain_rounded,
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
              style: const TextStyle(
                fontSize: 68,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -3,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.pine,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'MOVING TIME',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),

            const SizedBox(height: 40),

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

            const Spacer(flex: 3),

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
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: _confirmStop,
                      icon: const Icon(Icons.stop_rounded, size: 22),
                      label: const Text('Stop'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.alert,
                        foregroundColor: Colors.white,
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
            ? ('Auto-paused', AppColors.blaze)
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
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            Text(unit,
                style: const TextStyle(
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
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