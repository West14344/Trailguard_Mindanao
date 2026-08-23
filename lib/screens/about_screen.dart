import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'create_account_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Labelled back control, left-aligned above the content.
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text('How it works', style: text.headlineMedium),
                  const SizedBox(height: 20),

                  // The thesis. Everything else on this page supports it.
                  Text(
                    'Most hiking apps answer\n"where can I hike?"',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'TrailGuard answers "is it safe for me to hike there today?"',
                    style: text.headlineMedium?.copyWith(height: 1.3),
                  ),

                  const SizedBox(height: 30),

                  // Show the score rather than describe it — it's the
                  // product's core idea in one glance.
                  const SectionLabel('Every trail gets a score'),
                  const SizedBox(height: 14),
                  const _ScoreSample(
                    score: 92,
                    color: AppColors.forest,
                    verdict: 'Safe to go',
                    detail: 'Clear weather, dry trail',
                  ),
                  const SizedBox(height: 8),
                  const _ScoreSample(
                    score: 68,
                    color: AppColors.blaze,
                    verdict: 'Be careful',
                    detail: 'Rain expected this afternoon',
                  ),
                  const SizedBox(height: 8),
                  const _ScoreSample(
                    score: 35,
                    color: AppColors.alert,
                    verdict: "Don't go today",
                    detail: 'Flash flood risk reported',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'The score combines live weather, rainfall, terrain, recent '
                    'hazard reports from other hikers, and your own experience '
                    'level. A trail that is safe for a veteran can still be a '
                    'red for a beginner.',
                    style: text.bodyMedium?.copyWith(height: 1.6),
                  ),

                  const SizedBox(height: 34),

                  const SectionLabel('The problem'),
                  const SizedBox(height: 12),
                  Text(
                    'Hikers get hurt or stranded because they pick trails beyond '
                    'their skill level, get caught by sudden weather, run into '
                    'landslides or flooding, lose the path, or have no way to '
                    'call for help. Static maps leave that judgment to you.',
                    style: text.bodyMedium?.copyWith(height: 1.6),
                  ),

                  const SizedBox(height: 34),

                  const SectionLabel('What it does'),
                  const SizedBox(height: 14),
                  const _Feature(
                    icon: Icons.route_outlined,
                    title: 'Recommends trails that fit you',
                    body: 'Matched to your experience, fitness, and today\'s '
                        'conditions — not a generic difficulty rating.',
                  ),
                  const _Feature(
                    icon: Icons.cloud_download_outlined,
                    title: 'Works without signal',
                    body: 'Download the map before you leave and it keeps '
                        'working in dead zones.',
                  ),
                  const _Feature(
                    icon: Icons.thunderstorm_outlined,
                    title: 'Warns you before weather turns',
                    body: 'Heavy rain, storms, and flash flood alerts for the '
                        'trail you are on.',
                  ),
                  const _Feature(
                    icon: Icons.sos_outlined,
                    title: 'One-tap SOS',
                    body: 'Sends your location to your emergency contact and '
                        'the nearest ranger station.',
                  ),
                  const _Feature(
                    icon: Icons.groups_outlined,
                    title: 'Hikers report what they see',
                    body: 'Fallen trees, flooding, blocked paths — reported by '
                        'people who were just there.',
                  ),

                  const SizedBox(height: 24),

                  const SectionLabel('Who it is for'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _Tag('New hikers'),
                      _Tag('Frequent hikers'),
                      _Tag('Hiking groups'),
                      _Tag('Clubs and organizers'),
                      _Tag('Park and tourism staff'),
                      _Tag('Rangers and rescue teams'),
                    ],
                  ),

                  const SizedBox(height: 34),

                  // Closing note, set apart so it reads as the takeaway.
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.pine,
                      borderRadius: AppRadius.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: AppColors.moss, size: 26),
                        const SizedBox(height: 12),
                        Text(
                          'Stops accidents before they happen',
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Not just help after something goes wrong. Your '
                          'family knows where you are, and if you need help, '
                          'they can find you faster.',
                          style: TextStyle(
                            color: Color(0xFFC6DCCE),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Continue',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CreateAccountScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One example score, colour-coded, so the scale explains itself.
class _ScoreSample extends StatelessWidget {
  final int score;
  final Color color;
  final String verdict;
  final String detail;

  const _ScoreSample({
    required this.score,
    required this.color,
    required this.verdict,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.field,
            ),
            child: Center(
              child: Text(
                '$score%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verdict,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon, headline, one line of explanation.
class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Feature({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: AppRadius.field,
            ),
            child: Icon(icon, size: 21, color: AppColors.forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded label for the audience list.
class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.pine,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}