import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Everything here is hard-coded sample content. When a backend arrives,
/// swap these lists for API calls and the widgets stay untouched.

class Trail {
  final String name;
  final String region;
  final String difficulty;
  final String duration;
  final int safetyScore;
  final String weather;
  final String rainfallRisk;
  final String terrain;

  const Trail({
    required this.name,
    required this.region,
    required this.difficulty,
    required this.duration,
    required this.safetyScore,
    this.weather = 'Partly cloudy, 24°C',
    this.rainfallRisk = 'Low',
    this.terrain = 'Moderate',
  });

  /// Green above 80, amber 50–79, red below.
  Color get scoreColor {
    if (safetyScore >= 80) return AppColors.forest;
    if (safetyScore >= 50) return AppColors.blaze;
    return AppColors.alert;
  }

  String get verdict {
    if (safetyScore >= 80) return 'Safe to hike today';
    if (safetyScore >= 50) return 'Hike with caution today';
    return 'Not recommended today';
  }
}

const kTrails = <Trail>[
  Trail(
    name: 'Mt Apo Trail',
    region: 'Kapatagan',
    difficulty: 'Moderate',
    duration: '4h',
    safetyScore: 92,
  ),
  Trail(
    name: 'Kitanglad Ridge',
    region: 'Bukidnon',
    difficulty: 'Hard',
    duration: '6h',
    safetyScore: 68,
    weather: 'Overcast, 19°C',
    rainfallRisk: 'Moderate',
    terrain: 'Steep, exposed',
  ),
  Trail(
    name: 'Matigol Falls Path',
    region: 'Davao del Sur',
    difficulty: 'Easy',
    duration: '2h',
    safetyScore: 35,
    weather: 'Heavy rain, 22°C',
    rainfallRisk: 'High',
    terrain: 'Slippery rock',
  ),
];

enum AlertLevel { critical, caution, notice }

class TrailAlert {
  final String title;
  final String detail;
  final AlertLevel level;
  final IconData icon;

  const TrailAlert({
    required this.title,
    required this.detail,
    required this.level,
    required this.icon,
  });

  Color get background {
    switch (level) {
      case AlertLevel.critical:
        return AppColors.alert;
      case AlertLevel.caution:
        return AppColors.blaze;
      case AlertLevel.notice:
        return AppColors.fill;
    }
  }

  Color get foreground =>
      level == AlertLevel.notice ? AppColors.ink : Colors.white;
}

const kAlerts = <TrailAlert>[
  TrailAlert(
    title: 'Flash flood risk',
    detail: 'Matigol Falls · next 3 hours',
    level: AlertLevel.critical,
    icon: Icons.warning_amber_rounded,
  ),
  TrailAlert(
    title: 'Heavy rain expected',
    detail: 'Mt Apo Trail · 3–5pm today',
    level: AlertLevel.caution,
    icon: Icons.thunderstorm_outlined,
  ),
  TrailAlert(
    title: 'Fallen tree reported',
    detail: 'Mt Diwata · 2 hours ago',
    level: AlertLevel.notice,
    icon: Icons.park_outlined,
  ),
];

/// A hiker in your group. Distance between members is computed from these
/// coordinates rather than stored, so it stays correct as people move.
class GroupMember {
  final String name;
  final bool isYou;
  final double latitude;
  final double longitude;

  const GroupMember({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isYou = false,
  });
}

const kGroupName = 'ABACA HUNTERS';

/// Positions along the Mt Apo trail. Replace with live GPS when the
/// backend can exchange positions between group members.
const kGroupMembers = <GroupMember>[
  GroupMember(
    name: 'Nukie',
    latitude: 6.9875,
    longitude: 125.2731,
    isYou: true,
  ),
  GroupMember(
    name: 'Justin Nabunturan',
    latitude: 6.9878,
    longitude: 125.2734,
  ),
  GroupMember(
    name: 'CapyBara Awanon',
    latitude: 6.9841,
    longitude: 125.2709,
  ),
];

/// Single source of truth for the signed-in hiker while there is no backend.
class HikerProfile {
  static String fullName = 'Nukie Blaze';
  static String email = 'NukiebLaze@gmail.com';
  static String emergencyContact = 'Benhard Awanon';
  static String emergencyNumber = '+63 912 345 6789';
  static String experienceLevel = 'Intermediate Hiker';

  static String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Tracks whether the hiker is currently in a group. In-memory only —
/// a real build would persist this and sync with a backend.
class GroupSession {
  static bool isActive = false;
  static String name = '';
  static String code = '';

  static void start({required String groupName, required String groupCode}) {
    name = groupName;
    code = groupCode;
    isActive = true;
  }

  static void leave() {
    isActive = false;
    name = '';
    code = '';
  }
}