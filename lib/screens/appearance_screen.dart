import "package:flutter/material.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  static const _options = [
    (ThemeMode.light, "Light", "Bright screen, best in daylight",
        Icons.light_mode_outlined),
    (ThemeMode.dark, "Dark", "Easier on the eyes at dawn and dusk",
        Icons.dark_mode_outlined),
    (ThemeMode.system, "Match device", "Follows your phone settings",
        Icons.brightness_auto_outlined),
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
                    label: Text("Back"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text("Appearance",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Dark mode is easier to read on an early start or a "
                    "late descent.",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 26),
                  for (final (mode, name, subtitle, icon) in _options) ...[
                    _Option(
                      name: name,
                      subtitle: subtitle,
                      icon: icon,
                      selected: AppTheme.modeNotifier.value == mode,
                      onTap: () {
                        AppTheme.setMode(mode);
                        FirebaseService.saveTheme(AppTheme.modeCode);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
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

class _Option extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.name,
    required this.subtitle,
    required this.icon,
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
              Icon(icon, size: 22, color: AppColors.forest),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 2),
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











