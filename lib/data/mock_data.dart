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

class GroupMember {
  final String name;
  final String status;
  final bool onTrail;

  const GroupMember({
    required this.name,
    required this.status,
    required this.onTrail,
  });
}

const kGroupName = 'ABACA HUNTERS';

const kGroupMembers = <GroupMember>[
  GroupMember(name: 'Nukie (You)', status: 'On trail', onTrail: true),
  GroupMember(name: 'Justin Nabunturan', status: 'On trail', onTrail: true),
  GroupMember(name: 'CapyBara Awanon', status: '400m behind', onTrail: false),
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