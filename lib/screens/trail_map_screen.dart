import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/mock_data.dart';
import '../data/mountains.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'trail_detail_screen.dart';

class TrailMapScreen extends StatefulWidget {
  const TrailMapScreen({super.key});

  @override
  State<TrailMapScreen> createState() => _TrailMapScreenState();
}

class _TrailMapScreenState extends State<TrailMapScreen> {
  bool _onlyForMe = false;

  List<Trail> get _shown =>
      _onlyForMe ? suggestedFor(HikerProfile.levelRank) : kMountains;

  void _openSheet(Trail mountain) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mountain.name,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${mountain.region} · ${mountain.duration}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'See conditions',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => TrailDetailScreen(trail: mountain)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trail map',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('${shown.length} destinations across Mindanao',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),

                        Row(
              children: [
                _Toggle(
                  label: 'All',
                  selected: !_onlyForMe,
                  onTap: () => setState(() => _onlyForMe = false),
                ),
                const SizedBox(width: 8),
                _Toggle(
                  label: 'For me',
                  selected: _onlyForMe,
                  onTap: () => setState(() => _onlyForMe = true),
                ),
                const Spacer(),
                const _LegendDot(color: AppColors.forest, label: 'Beg.'),
                const SizedBox(width: 8),
                const _LegendDot(color: AppColors.blaze, label: 'Int.'),
                const SizedBox(width: 8),
                const _LegendDot(color: AppColors.alert, label: 'Adv.'),
              ],
            ),
            const SizedBox(height: 14),

            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.card,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(7.8, 125.0),
                    initialZoom: 7,
                    minZoom: 5,
                    maxZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.trailguard_ai',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final m in shown)
                          Marker(
                            point: LatLng(m.latitude, m.longitude),
                            width: 26,
                            height: 26,
                            child: GestureDetector(
                              onTap: () => _openSheet(m),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: m.levelColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            PrimaryButton(
              label: 'Download offline map',
              icon: Icons.download_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline download needs the backend'),
                    backgroundColor: AppColors.pine,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Toggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.forest : AppColors.card,
      borderRadius: AppRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            border: Border.all(
                color: selected ? AppColors.forest : AppColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}