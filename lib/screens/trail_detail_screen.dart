import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class TrailDetailScreen extends StatelessWidget {
  final Trail trail;
  const TrailDetailScreen({super.key, required this.trail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  Text('${trail.region} · ${trail.difficulty} · ${trail.duration}',
                      style: Theme.of(context).textTheme.bodySmall),

                  const SizedBox(height: 28),

                  // The ring fills to the score and takes its colour from
                  // the same thresholds used everywhere else.
                  Center(
                    child: ScoreRing(
                      score: trail.safetyScore,
                      color: trail.scoreColor,
                      size: 190,
                    ),
                  ),
                  const SizedBox(height: 22),

                  Center(
                    child: Text(
                      trail.verdict,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: trail.scoreColor, fontSize: 19),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text('Updated 12 minutes ago',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),

                  const SizedBox(height: 30),

                  const SectionLabel("Today's conditions"),
                  const SizedBox(height: 12),
                  _ConditionRow(
                    icon: Icons.cloud_outlined,
                    label: 'Weather',
                    value: trail.weather,
                  ),
                  const SizedBox(height: 10),
                  _ConditionRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Rainfall risk',
                    value: trail.rainfallRisk,
                  ),
                  const SizedBox(height: 10),
                  _ConditionRow(
                    icon: Icons.terrain_outlined,
                    label: 'Terrain',
                    value: trail.terrain,
                  ),

                  const SizedBox(height: 30),

                  PrimaryButton(
                    label: 'Start hike',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hike started on ${trail.name}'),
                          backgroundColor: AppColors.pine,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Report hazard',
                    icon: Icons.flag_outlined,
                    color: AppColors.blaze,
                    onPressed: () {
                      // TODO: push HazardReportScreen once it exists.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hazard reporting comes next'),
                          backgroundColor: AppColors.pine,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
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

/// One labelled condition row.
class _ConditionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConditionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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