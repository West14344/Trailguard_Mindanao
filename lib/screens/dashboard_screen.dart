import 'package:flutter/material.dart';
import '../data/hike_records.dart';
import '../data/mock_data.dart';
import '../data/mountains.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'hike_tracking_view.dart';
import 'mountains_screen.dart';
import 'trail_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _openTrail(Trail trail) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrailDetailScreen(trail: trail)),
    );
    // A hike may have started while we were away.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // The dashboard becomes the tracker while a hike is running.
    if (ActiveHike.isActive) {
      return HikeTrackingView(onFinished: () => setState(() {}));
    }

    final suggestions = suggestedFor(HikerProfile.levelRank);
    final featured = suggestions.isEmpty ? kMountains.first : suggestions.first;
    final topThree = suggestions.take(3).toList();
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
                    SizedBox(height: 2),
                    Text(firstName,
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final next = AppTheme.isDark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  AppTheme.setMode(next);
                  FirebaseService.saveTheme(AppTheme.modeCode);
                },
                icon: Icon(
                  AppTheme.isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_outlined,
                  color: AppColors.ink,
                ),
                tooltip: AppTheme.isDark
                    ? "Switch to light mode"
                    : "Switch to dark mode",
              ),
            ],
          ),
          SizedBox(height: 18),

          _HeroCard(trail: featured, onTap: () => _openTrail(featured)),

          if (HikeLog.totalHikes > 0) ...[
            SizedBox(height: 14),
            _TotalsStrip(),
          ],

          if (HikeLog.readyToLevelUp) ...[
            SizedBox(height: 14),
            _LevelUpNudge(),
          ],

          SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: SectionLabel(
                    'Matched to ${HikerProfile.levelName.toLowerCase()}'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MountainsScreen()),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.forest,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View all',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          for (final mountain in topThree) ...[
            MountainRow(mountain: mountain),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 4),
          SecondaryButton(
            label: 'View all ${kMountains.length} mountains',
            icon: Icons.terrain_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MountainsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Running totals, only shown once there is something to total.
class _TotalsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _Total(
              value: '${HikeLog.totalHikes}',
              label: HikeLog.totalHikes == 1 ? 'hike' : 'hikes'),
          Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: AppColors.line),
          _Total(
              value: HikeLog.totalKm.toStringAsFixed(1), label: 'km total'),
          Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: AppColors.line),
          _Total(
              value: '${HikeLog.earnedBadgeCount}', label: 'badges'),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String value;
  final String label;
  const _Total({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: AppColors.heroFill,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Appears after five hikes at the current level.
class _LevelUpNudge extends StatelessWidget {
  const _LevelUpNudge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1AE3712B),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.blaze.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded,
              size: 22, color: AppColors.blaze),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready for harder trails?',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Five ${HikerProfile.levelName.toLowerCase()} hikes done. '
                  'Change your level in Profile to unlock more.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark card at the top. Tapping it opens the live conditions.
class _HeroCard extends StatelessWidget {
  final Trail trail;
  final VoidCallback onTap;
  const _HeroCard({required this.trail, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.heroFill,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PICKED FOR YOU TODAY',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.moss,
                ),
              ),
              SizedBox(height: 12),
              Text(
                trail.name,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: AppColors.onHero,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 15, color: AppColors.moss),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      trail.region,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Color(0xFFC6DCCE), fontSize: 13),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _Pill(text: trail.difficulty),
                  SizedBox(width: 8),
                  _Pill(text: trail.duration),
                  const Spacer(),
                  Text(
                    'See conditions',
                    style: TextStyle(
                      color: AppColors.moss,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.moss),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x337FB69E),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.moss,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}















