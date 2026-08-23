import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'trail_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final featured = kTrails.first;
    final firstName = HikerProfile.fullName.split(' ').first;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(firstName,
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.ink),
                tooltip: 'Notifications',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Hero: today's score for the trail the hiker is headed to.
          _HeroScoreCard(trail: featured),
          const SizedBox(height: 26),

          const SectionLabel('Recommended for you'),
          const SizedBox(height: 12),
          for (final trail in kTrails) ...[
            _TrailRow(trail: trail),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0x1AE3712B),
                    borderRadius: AppRadius.field,
                  ),
                  child: const Icon(Icons.thunderstorm_outlined,
                      color: AppColors.blaze, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Heavy rain expected 3–5pm',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('Near Matigol Falls',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The dark card at the top: one number, stated plainly.
class _HeroScoreCard extends StatelessWidget {
  final Trail trail;
  const _HeroScoreCard({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.pine,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRAIL SAFETY SCORE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.moss,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${trail.safetyScore}',
                style: const TextStyle(
                  fontSize: 62,
                  height: 0.95,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                  color: Colors.white,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 2),
                child: Text('%',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x337FB69E),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Text(
                    'Safe today',
                    style: TextStyle(
                      color: AppColors.moss,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.moss),
              const SizedBox(width: 6),
              Text(
                '${trail.name} · ${trail.region}',
                style: const TextStyle(color: Color(0xFFC6DCCE), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One row in the recommended list.
class _TrailRow extends StatelessWidget {
  final Trail trail;
  const _TrailRow({required this.trail});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrailDetailScreen(trail: trail)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trail.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text('${trail.difficulty} · ${trail.duration}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ScoreChip(score: trail.safetyScore, color: trail.scoreColor),
        ],
      ),
    );
  }
}