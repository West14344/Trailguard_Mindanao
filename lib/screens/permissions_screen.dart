import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'main_shell.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  // Cosmetic only for now â€” no permission_handler calls yet.
  final _granted = <bool>[true, true, false];

  static const _items = [
    ['Location access', 'Powers trail safety scoring and SOS'],
    ['Notifications', 'Weather and hazard alerts while you hike'],
    ['Offline maps', 'Download maps for no-signal areas'],
  ];

  static const _icons = [
    Icons.location_on_outlined,
    Icons.notifications_none_rounded,
    Icons.download_outlined,
  ];

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
                    icon: Icon(Icons.arrow_back, size: 20),
                    label: Text('Back'),
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
                  const _StepBar(step: 3),
                  const SizedBox(height: 18),

                  Text(
                    'Enable permissions',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location is what makes safety scoring and SOS work. You '
                    'can change any of these later in Profile.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 26),

                  for (var i = 0; i < _items.length; i++) ...[
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color:
                                  _granted[i] ? AppColors.mist : AppColors.fill,
                              borderRadius: AppRadius.field,
                            ),
                            child: Icon(
                              _icons[i],
                              size: 22,
                              color: _granted[i]
                                  ? AppColors.forest
                                  : AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _items[i][0],
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                SizedBox(height: 3),
                                Text(
                                  _items[i][1],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _granted[i],
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.forest,
                            onChanged: (v) => setState(() => _granted[i] = v),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  SizedBox(height: 8),
                  // Honest about what happens if location stays off, rather
                  // than blocking the user or nagging.
                  if (!_granted[0])
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: AppColors.blaze),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Without location, trails cannot be scored for '
                            'where you are and SOS cannot share your position.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.blaze),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Go to dashboard',
                // Clears the whole onboarding stack so Back cannot land
                // someone back in the sign-up flow.
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (route) => false,
                ),
              ),
            ),
          ],
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
        SizedBox(width: 12),
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










