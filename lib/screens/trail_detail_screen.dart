import 'package:flutter/material.dart';
import '../data/hike_records.dart';
import '../data/mock_data.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'hazard_report_screen.dart';

class TrailDetailScreen extends StatefulWidget {
  final Trail trail;
  const TrailDetailScreen({super.key, required this.trail});

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  late Future<TrailConditions> _conditions = _load();

  Future<TrailConditions> _load() => WeatherService.fetch(
        latitude: widget.trail.latitude,
        longitude: widget.trail.longitude,
        difficulty: widget.trail.difficulty,
      );

  void _startHike() {
    ActiveHike.start(widget.trail);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking started on ${widget.trail.name}'),
        backgroundColor: AppColors.pine,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;
    final alreadyRunning = ActiveHike.isActive;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back, size: 20),
                    label: Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _conditions = _load()),
                    icon: Icon(Icons.refresh_rounded,
                        color: AppColors.forest),
                    tooltip: 'Refresh conditions',
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text(trail.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${trail.region} · ${trail.difficulty} · ${trail.duration}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 26),

                  FutureBuilder<TrailConditions>(
                    future: _conditions,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _LoadingConditions();
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return _ConditionsError(
                          onRetry: () => setState(() => _conditions = _load()),
                        );
                      }
                      return _ConditionsView(
                        conditions: snapshot.data!,
                        trail: trail,
                      );
                    },
                  ),

                  SizedBox(height: 30),
                  PrimaryButton(
                    label: alreadyRunning ? 'Hike already running' : 'Start hike',
                    icon: Icons.play_arrow_rounded,
                    onPressed: alreadyRunning ? null : _startHike,
                  ),
                  if (alreadyRunning) ...[
                    SizedBox(height: 8),
                    Text(
                      'Finish the hike on your Home tab before starting another.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Report hazard',
                    icon: Icons.flag_outlined,
                    color: AppColors.blaze,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => HazardReportScreen(trail: trail)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionsView extends StatelessWidget {
  final TrailConditions conditions;
  final Trail trail;

  const _ConditionsView({required this.conditions, required this.trail});

  @override
  Widget build(BuildContext context) {
    final score = conditions.safetyScore;
    final color = scoreColorFor(score);

    return Column(
      children: [
        Center(child: ScoreRing(score: score, color: color, size: 190)),
        const SizedBox(height: 22),
        Center(
          child: Text(
            verdictFor(score),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: color, fontSize: 19),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('Live conditions · updated just now',
              style: Theme.of(context).textTheme.bodySmall),
        ),

        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft,
          child: SectionLabel('Right now'),
        ),
        const SizedBox(height: 12),
        _Row(
          icon: Icons.cloud_outlined,
          label: 'Weather',
          value: conditions.summary,
        ),
        const SizedBox(height: 10),
        _Row(
          icon: Icons.water_drop_outlined,
          label: 'Rainfall risk',
          value:
              '${conditions.rainfallRisk} · ${conditions.dailyRainMm.toStringAsFixed(1)} mm today',
        ),
        const SizedBox(height: 10),
        _Row(
          icon: Icons.air_rounded,
          label: 'Wind',
          value: conditions.windSummary,
        ),
        const SizedBox(height: 10),
        _Row(
          icon: Icons.hiking_rounded,
          label: 'Difficulty',
          value: trail.difficulty,
        ),

        if (conditions.forecast.isNotEmpty) ...[
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: SectionLabel('7-day outlook'),
          ),
          const SizedBox(height: 12),
          // Seven days scroll horizontally; fitting them all on screen
          // would shrink each card below readable size.
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: conditions.forecast.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: 80,
                child: _DayCard(day: conditions.forecast[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.swipe_rounded, size: 14, color: AppColors.inkSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Swipe for the full week. Days four onward are less certain.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LoadingConditions extends StatelessWidget {
  const _LoadingConditions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.forest),
          ),
        ),
        const SizedBox(height: 22),
        Text('Checking live conditions‚¬¦',
            style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ConditionsError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ConditionsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 38, color: AppColors.inkSoft),
          const SizedBox(height: 12),
          Text("Couldn't reach the weather service",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SecondaryButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.forest),
          const SizedBox(width: 13),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}














/// One day in the week-long forecast.
class _DayCard extends StatelessWidget {
  final DayConditions day;
  const _DayCard({required this.day});

  IconData get _icon {
    final c = day.weatherCode;
    if (c == 0) return Icons.wb_sunny_outlined;
    if (c <= 3) return Icons.cloud_outlined;
    if (c <= 48) return Icons.foggy;
    if (c <= 67) return Icons.water_drop_outlined;
    if (c <= 86) return Icons.grain_rounded;
    return Icons.thunderstorm_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = scoreColorFor(day.safetyScore);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.shortDay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 7),
          // Later days are drawn fainter, so the strip itself shows that
          // confidence tails off rather than only saying so.
          Icon(_icon,
              size: 23,
              color: day.isLessCertain
                  ? AppColors.inkSoft.withAlpha(120)
                  : AppColors.inkSoft),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              '${day.safetyScore}%',
              style: TextStyle(
                color: AppColors.onAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${day.maxTempC.round()}/${day.minTempC.round()}C',
            style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
          ),
          Text(
            '${day.rainMm.toStringAsFixed(1)} mm',
            style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
