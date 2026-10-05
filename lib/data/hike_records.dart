import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'mock_data.dart';

/// One completed hike. Distance and time come from the tracked session,
/// so the numbers in Achievements are earned rather than assumed.
class HikeRecord {
  final String mountainName;
  final String region;
  final String difficulty;
  final double distanceKm;
  final Duration movingTime;
  final DateTime completedAt;

  const HikeRecord({
    required this.mountainName,
    required this.region,
    required this.difficulty,
    required this.distanceKm,
    required this.movingTime,
    required this.completedAt,
  });

  int get levelRank => switch (difficulty) {
        'Beginner' => 0,
        'Advanced' => 2,
        _ => 1,
      };

  Color get levelColor => switch (levelRank) {
        0 => AppColors.forest,
        2 => AppColors.alert,
        _ => AppColors.blaze,
      };

  double? get paceMinPerKm {
    if (distanceKm < 0.05) return null;
    return movingTime.inSeconds / 60 / distanceKm;
  }
}

/// Completed hikes for the signed-in hiker. Loaded from Firestore at login
/// and appended locally as hikes finish.
class HikeLog {
  static final List<HikeRecord> records = [];

  static void add(HikeRecord record) => records.insert(0, record);

  static int get totalHikes => records.length;

  static double get totalKm =>
      records.fold(0.0, (sum, r) => sum + r.distanceKm);

  static Duration get totalTime => records.fold(
        Duration.zero,
        (sum, r) => sum + r.movingTime,
      );

  static int countAtLevel(int rank) =>
      records.where((r) => r.levelRank == rank).length;

  static Set<String> get uniqueMountains =>
      records.map((r) => r.mountainName).toSet();

  static List<HikeBadge> get badges => [
        HikeBadge(
          name: 'First summit',
          description: 'Complete your first hike',
          icon: Icons.flag_rounded,
          earned: totalHikes >= 1,
          progress: '$totalHikes/1',
        ),
        HikeBadge(
          name: 'Getting the habit',
          description: 'Complete five hikes',
          icon: Icons.repeat_rounded,
          earned: totalHikes >= 5,
          progress: '$totalHikes/5',
        ),
        HikeBadge(
          name: 'Fifty club',
          description: 'Cover 50 km in total',
          icon: Icons.straighten_rounded,
          earned: totalKm >= 50,
          progress: '${totalKm.toStringAsFixed(1)}/50 km',
        ),
        HikeBadge(
          name: 'Century club',
          description: 'Cover 100 km in total',
          icon: Icons.military_tech_rounded,
          earned: totalKm >= 100,
          progress: '${totalKm.toStringAsFixed(1)}/100 km',
        ),
        HikeBadge(
          name: 'Stepping up',
          description: 'Finish an intermediate trail',
          icon: Icons.trending_up_rounded,
          earned: countAtLevel(1) >= 1,
          progress: '${countAtLevel(1)}/1',
        ),
        HikeBadge(
          name: 'Summit seeker',
          description: 'Finish three advanced trails',
          icon: Icons.terrain_rounded,
          earned: countAtLevel(2) >= 3,
          progress: '${countAtLevel(2)}/3',
        ),
        HikeBadge(
          name: 'Explorer',
          description: 'Visit ten different mountains',
          icon: Icons.explore_rounded,
          earned: uniqueMountains.length >= 10,
          progress: '${uniqueMountains.length}/10',
        ),
        HikeBadge(
          name: 'Long hauler',
          description: 'Spend 10 hours on the trail',
          icon: Icons.schedule_rounded,
          earned: totalTime.inHours >= 10,
          progress: '${totalTime.inHours}/10 h',
        ),
      ];

  static int get earnedBadgeCount => badges.where((b) => b.earned).length;

  /// Suggests moving up a level once five hikes at the current level are
  /// behind them.
  static bool get readyToLevelUp {
    final rank = HikerProfile.levelRank;
    if (rank >= 2) return false;
    return countAtLevel(rank) >= 5;
  }
}

class HikeBadge {
  final String name;
  final String description;
  final IconData icon;
  final bool earned;
  final String progress;

  const HikeBadge({
    required this.name,
    required this.description,
    required this.icon,
    required this.earned,
    required this.progress,
  });
}

/// The hike currently being tracked. Kept in memory while running and
/// written to Firestore once, when it finishes.
class ActiveHike {
  static Trail? trail;
  static double distanceKm = 0;
  static Duration elapsed = Duration.zero;
  static bool isPaused = false;
  static bool isAutoPaused = false;

  /// Last GPS fix, so SOS and hazard reports know where the hiker is.
  static double? latitude;
  static double? longitude;
  static double? accuracyM;

  static bool get isActive => trail != null;

  static void start(Trail t) {
    trail = t;
    distanceKm = 0;
    elapsed = Duration.zero;
    isPaused = false;
    isAutoPaused = false;
    latitude = null;
    longitude = null;
    accuracyM = null;
  }

  static HikeRecord? finish() {
    final t = trail;
    if (t == null) return null;

    final record = HikeRecord(
      mountainName: t.name,
      region: t.region,
      difficulty: t.difficulty,
      distanceKm: distanceKm,
      movingTime: elapsed,
      completedAt: DateTime.now(),
    );

    HikeLog.add(record);
    // Shown locally at once; the cloud write happens in the background.
    FirebaseService.saveHike(record);
    clear();
    return record;
  }

  static void clear() {
    trail = null;
    distanceKm = 0;
    elapsed = Duration.zero;
    isPaused = false;
    isAutoPaused = false;
    latitude = null;
    longitude = null;
    accuracyM = null;
  }
}

/// h:mm:ss, dropping the hour when it is zero.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}











