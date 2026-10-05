import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "../data/mock_data.dart";
import "../data/mountains.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";
import "trail_detail_screen.dart";

class TrailMapScreen extends StatefulWidget {
  const TrailMapScreen({super.key});

  @override
  State<TrailMapScreen> createState() => _TrailMapScreenState();
}

class _TrailMapScreenState extends State<TrailMapScreen> {
  bool _onlyForMe = false;
  bool _showHazards = true;

  List<Trail> get _shown =>
      _onlyForMe ? suggestedFor(HikerProfile.levelRank) : kMountains;

  void _openTrailSheet(Trail mountain) {
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: AppRadius.field,
                    ),
                    child: Icon(Icons.terrain_rounded,
                        size: 21, color: AppColors.forest),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mountain.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text("${mountain.region} - ${mountain.duration}",
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: "See conditions",
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

  void _openHazardSheet(HazardReport hazard) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: hazard.markerColor.withAlpha(30),
                      borderRadius: AppRadius.field,
                    ),
                    child: Icon(hazard.icon,
                        size: 22, color: hazard.markerColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hazard.type,
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: 2),
                        Text("${hazard.nearestTrail} - ${hazard.ago}",
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              if (hazard.description.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  hazard.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5),
                ),
              ],
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 15, color: AppColors.inkSoft),
                  SizedBox(width: 6),
                  Text("Reported by ${hazard.reportedByName}",
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              if (hazard.hasPosition) ...[
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 15, color: AppColors.inkSoft),
                    const SizedBox(width: 6),
                    Text(
                      "${hazard.latitude!.toStringAsFixed(4)}, "
                      "${hazard.longitude!.toStringAsFixed(4)}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
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
      child: StreamBuilder<List<HazardReport>>(
        stream: FirebaseService.hazardReportStream(),
        builder: (context, snapshot) {
          final hazards = (snapshot.data ?? const <HazardReport>[])
              .where((h) => h.hasPosition)
              .toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Trail map",
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  hazards.isEmpty
                      ? "${shown.length} destinations across Mindanao"
                      : "${shown.length} destinations - "
                          "${hazards.length} active "
                          "${hazards.length == 1 ? "hazard" : "hazards"}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 12),

                Row(
                  children: [
                    _Toggle(
                      label: "All",
                      selected: !_onlyForMe,
                      onTap: () => setState(() => _onlyForMe = false),
                    ),
                    SizedBox(width: 8),
                    _Toggle(
                      label: "For me",
                      selected: _onlyForMe,
                      onTap: () => setState(() => _onlyForMe = true),
                    ),
                    SizedBox(width: 8),
                    _Toggle(
                      label: "Hazards",
                      selected: _showHazards,
                      selectedColor: AppColors.alert,
                      icon: Icons.warning_amber_rounded,
                      onTap: () =>
                          setState(() => _showHazards = !_showHazards),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: "com.example.trailguard_ai",
                        ),

                        // Trails underneath, so a hazard pin is never
                        // hidden behind a mountain marker.
                        MarkerLayer(
                          markers: [
                            for (final m in shown)
                              Marker(
                                point: LatLng(m.latitude, m.longitude),
                                width: 26,
                                height: 26,
                                child: GestureDetector(
                                  onTap: () => _openTrailSheet(m),
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

                        if (_showHazards)
                          MarkerLayer(
                            markers: [
                              for (final h in hazards)
                                Marker(
                                  point:
                                      LatLng(h.latitude!, h.longitude!),
                                  width: 36,
                                  height: 36,
                                  child: GestureDetector(
                                    onTap: () => _openHazardSheet(h),
                                    child: _HazardPin(hazard: h),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),

                Row(
                  children: [
                    _LegendDot(
                        color: AppColors.forest, label: "Beginner"),
                    SizedBox(width: 10),
                    _LegendDot(
                        color: AppColors.blaze, label: "Interm."),
                    SizedBox(width: 10),
                    _LegendDot(
                        color: AppColors.alert, label: "Advanced"),
                    const Spacer(),
                    if (_showHazards && hazards.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.alert),
                          SizedBox(width: 4),
                          Text("Hazard",
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: 12),

                PrimaryButton(
                  label: "Download offline map",
                  icon: Icons.download_outlined,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Offline download is planned"),
                        backgroundColor: AppColors.pine,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Teardrop-ish marker so hazards read differently from round trail pins.
class _HazardPin extends StatelessWidget {
  final HazardReport hazard;
  const _HazardPin({required this.hazard});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hazard.markerColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Icon(hazard.icon, size: 17, color: Colors.white),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final IconData? icon;

  const _Toggle({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedColor ?? AppColors.forest;

    return Material(
      color: selected ? active : AppColors.card,
      borderRadius: AppRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            border:
                Border.all(color: selected ? active : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14,
                    color: selected ? Colors.white : AppColors.inkSoft),
                SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ],
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











