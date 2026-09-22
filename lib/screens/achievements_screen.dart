import 'package:flutter/material.dart';
import '../data/hike_records.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = HikeLog.records;
    final badges = HikeLog.badges;

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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  Text('Achievements',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${HikeLog.earnedBadgeCount} of ${badges.length} badges earned',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 22),

                  const SectionLabel('Badges'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: badges.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.35,
                    ),
                    itemBuilder: (context, i) => _BadgeTile(badge: badges[i]),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: SectionLabel('Mountains climbed')),
                      Text('${records.length}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (records.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.hiking_rounded,
                              size: 38, color: AppColors.inkSoft),
                          const SizedBox(height: 12),
                          Text('No hikes yet',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Pick a mountain, tap Start hike, and it will be '
                            'recorded here when you finish.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final record in records) ...[
                      _RecordCard(record: record),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final HikeBadge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: earned ? AppColors.mist : AppColors.card,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: earned ? AppColors.forest : AppColors.line,
          width: earned ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            earned ? badge.icon : Icons.lock_outline_rounded,
            size: 24,
            color: earned ? AppColors.forest : AppColors.inkSoft,
          ),
          const Spacer(),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: earned ? AppColors.pine : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            earned ? badge.description : badge.progress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final HikeRecord record;
  const _RecordCard({required this.record});

  String get _date {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = record.completedAt;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(record.mountainName,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: record.levelColor,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  record.difficulty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text('${record.region} · $_date',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(
                icon: Icons.straighten_rounded,
                value: '${record.distanceKm.toStringAsFixed(2)} km',
              ),
              const SizedBox(width: 20),
              _Metric(
                icon: Icons.schedule_rounded,
                value: formatDuration(record.movingTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  const _Metric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.forest),
        const SizedBox(width: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
      ],
    );
  }
}