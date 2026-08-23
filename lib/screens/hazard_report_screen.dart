import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class HazardReportScreen extends StatefulWidget {
  const HazardReportScreen({super.key});

  @override
  State<HazardReportScreen> createState() => _HazardReportScreenState();
}

class _HazardReportScreenState extends State<HazardReportScreen> {
  int? _selectedType;
  bool _photoAttached = false;
  final _notes = TextEditingController();

  static const _labels = [
    'Fallen tree',
    'Flooded trail',
    'Wildfire',
    'Landslide',
  ];

  static const _icons = [
    Icons.park_outlined,
    Icons.water_outlined,
    Icons.local_fire_department_outlined,
    Icons.landslide_outlined,
  ];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hazard reported. Nearby hikers have been notified.'),
        backgroundColor: AppColors.pine,
        behavior: SnackBarBehavior.floating,
      ),
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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text('Report a hazard',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Other hikers on this trail see your report straight away.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 26),

                  const SectionLabel('Hazard type'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _typeTile(0)),
                      const SizedBox(width: 12),
                      Expanded(child: _typeTile(1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _typeTile(2)),
                      const SizedBox(width: 12),
                      Expanded(child: _typeTile(3)),
                    ],
                  ),

                  const SizedBox(height: 26),
                  const SectionLabel('Photo'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _photoAttached = !_photoAttached),
                    child: Container(
                      height: 132,
                      decoration: BoxDecoration(
                        color:
                            _photoAttached ? AppColors.mist : AppColors.fill,
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: _photoAttached
                              ? AppColors.forest
                              : AppColors.line,
                          width: _photoAttached ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _photoAttached
                                ? Icons.check_circle_outline
                                : Icons.photo_camera_outlined,
                            size: 34,
                            color: _photoAttached
                                ? AppColors.forest
                                : AppColors.inkSoft,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _photoAttached ? 'Photo attached' : 'Add a photo',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),
                  LabeledField(
                    label: 'Notes',
                    hint: 'Describe what you saw',
                    controller: _notes,
                    maxLines: 4,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Submit report',
                onPressed: _selectedType == null ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTile(int index) {
    final selected = _selectedType == index;

    return Material(
      color: selected ? const Color(0x14E3712B) : AppColors.card,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: () => setState(() => _selectedType = index),
        borderRadius: AppRadius.card,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? AppColors.blaze : AppColors.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[index],
                  size: 26,
                  color: selected ? AppColors.blaze : AppColors.inkSoft),
              const SizedBox(height: 8),
              Text(
                _labels[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.blaze : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}