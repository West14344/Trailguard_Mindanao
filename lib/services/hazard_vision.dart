import "package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart";

/// A suggested hazard type, read from the photo the hiker just took.
class HazardGuess {
  final String type;
  final double confidence;
  final List<String> rawLabels;

  const HazardGuess({
    required this.type,
    required this.confidence,
    required this.rawLabels,
  });

  /// Below this the suggestion is not worth showing, since a wrong guess
  /// that the hiker accepts without thinking is worse than no guess.
  bool get isUseful => confidence >= 0.55;

  int get percent => (confidence * 100).round();
}

/// Reads a hazard photo with Google's on-device image labeller and maps
/// its generic labels onto the app's own hazard types.
///
/// The model is general-purpose, not trained on trail hazards, so this is
/// a suggestion the hiker confirms rather than an automatic decision.
/// Everything runs on the device, so it still works with no signal.
class HazardVision {
  static final _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.45),
  );

  /// Generic labels the model returns, mapped to our nine hazard types.
  /// Several labels can point at the same hazard; the strongest wins.
  static const _mapping = <String, String>{
    // Flooding
    "Water": "Flooded trail",
    "Flood": "Flooded trail",
    "River": "Flooded trail",
    "Lake": "Flooded trail",
    "Waterfall": "Flooded trail",
    "Rain": "Flooded trail",
    "Wave": "Flooded trail",
    "Reservoir": "Flooded trail",
    // Fire
    "Fire": "Wildfire",
    "Flame": "Wildfire",
    "Smoke": "Wildfire",
    "Bonfire": "Wildfire",
    "Campfire": "Wildfire",
    // Fallen tree
    "Tree": "Fallen tree",
    "Trunk": "Fallen tree",
    "Branch": "Fallen tree",
    "Wood": "Fallen tree",
    "Log": "Fallen tree",
    "Forest": "Fallen tree",
    "Jungle": "Fallen tree",
    // Landslide
    "Soil": "Landslide",
    "Mud": "Landslide",
    "Cliff": "Landslide",
    "Rock": "Landslide",
    "Boulder": "Landslide",
    "Canyon": "Landslide",
    "Sand": "Landslide",
    // Bridge
    "Bridge": "Damaged bridge",
    "Pier": "Damaged bridge",
    // Wildlife
    "Dog": "Wildlife",
    "Snake": "Wildlife",
    "Monkey": "Wildlife",
    "Bird": "Wildlife",
    "Insect": "Wildlife",
    "Cattle": "Wildlife",
    "Horse": "Wildlife",
    "Wildlife": "Wildlife",
    // Signage
    "Sign": "Missing trail sign",
    "Signage": "Missing trail sign",
    "Street sign": "Missing trail sign",
    "Traffic sign": "Missing trail sign",
    // Blocked path
    "Fence": "Blocked path",
    "Gate": "Blocked path",
    "Wall": "Blocked path",
    "Barrier": "Blocked path",
  };

  /// Returns a suggestion, or null when the photo is unreadable or the
  /// labels do not map to any hazard the app knows about.
  static Future<HazardGuess?> inspect(String imagePath) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final labels = await _labeler.processImage(input);
      if (labels.isEmpty) return null;

      final raw = labels.map((l) => l.label).toList();

      // Sum confidence per hazard type: three water-ish labels should
      // outweigh one weak tree label.
      final scores = <String, double>{};
      for (final l in labels) {
        final hazard = _mapping[l.label];
        if (hazard == null) continue;
        scores[hazard] = (scores[hazard] ?? 0) + l.confidence;
      }
      if (scores.isEmpty) return null;

      final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
      return HazardGuess(
        type: best.key,
        confidence: best.value.clamp(0.0, 1.0),
        rawLabels: raw.take(4).toList(),
      );
    } catch (_) {
      // A failed read should never block a hazard report.
      return null;
    }
  }

  static Future<void> dispose() => _labeler.close();
}
