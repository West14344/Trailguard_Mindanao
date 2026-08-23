import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'permissions_screen.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key});

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  int _selected = 1;
  double _difficulty = 0.5;

  static const _levels = [
    ['Beginner', 'New to hiking'],
    ['Intermediate', 'Hike a few times a year'],
    ['Advanced', 'Frequent, technical trails'],
  ];

  String get _difficultyLabel {
    if (_difficulty < 0.34) return 'Gentle';
    if (_difficulty < 0.67) return 'Moderate';
    return 'Demanding';
  }

  String get _difficultyHint {
    if (_difficulty < 0.34) return 'Well-marked paths, gradual climbs';
    if (_difficulty < 0.67) return 'Some steep sections and rough ground';
    return 'Long climbs, scrambling, exposed ridges';
  }

  void _continue() {
    HikerProfile.experienceLevel = '${_levels[_selected][0]} Hiker';

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExperienceScreen()),
    );
  }

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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  const _StepBar(step: 2),
                  const SizedBox(height: 18),

                  Text(
                    "What's your hiking experience?",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This changes how strictly trails are scored for you. The '
                    'same trail can be green for one hiker and red for another.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  for (var i = 0; i < _levels.length; i++) ...[
                    _LevelOption(
                      title: _levels[i][0],
                      subtitle: _levels[i][1],
                      selected: _selected == i,
                      onTap: () => setState(() => _selected = i),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionLabel('Preferred difficulty'),
                      Text(
                        _difficultyLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.forest),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.forest,
                      inactiveTrackColor: AppColors.fill,
                      thumbColor: AppColors.forest,
                      overlayColor: const Color(0x1F1B7A4B),
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: _difficulty,
                      onChanged: (v) => setState(() => _difficulty = v),
                    ),
                  ),
                  // Naming what the slider position means, so the control
                  // isn't just an abstract line.
                  Text(
                    _difficultyHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Continue',
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One selectable experience level.
class _LevelOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LevelOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mist : AppColors.card,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.forest : AppColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-segment progress bar shared by the onboarding steps.
class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('STEP $step OF 3', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: i < step ? AppColors.forest : AppColors.fill,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}