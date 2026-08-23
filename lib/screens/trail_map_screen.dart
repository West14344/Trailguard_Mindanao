import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

/// Trailhead coordinates for the sample trails.
const _kTrailPoints = <String, LatLng>{
  'Mt Apo Trail': LatLng(6.9875, 125.2731),
  'Kitanglad Ridge': LatLng(8.1500, 124.9167),
  'Matigol Falls Path': LatLng(6.7500, 125.3500),
};

class TrailMapScreen extends StatelessWidget {
  const TrailMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            Text(
              "Trailheads coloured by today's safety score",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.card,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(7.2, 125.1),
                    initialZoom: 8.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.trailguard_ai',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final trail in kTrails)
                          if (_kTrailPoints[trail.name] != null)
                            Marker(
                              point: _kTrailPoints[trail.name]!,
                              width: 44,
                              height: 44,
                              child: _TrailPin(trail: trail),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

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

/// Pin colour carries the same meaning as the score chips elsewhere.
class _TrailPin extends StatelessWidget {
  final Trail trail;
  const _TrailPin({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${trail.name} · ${trail.safetyScore}%',
      child: Container(
        decoration: BoxDecoration(
          color: trail.scoreColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(
          child: Text(
            '${trail.safetyScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}