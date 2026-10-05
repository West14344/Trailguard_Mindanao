import "package:flutter/material.dart";
import "../theme/app_theme.dart";

/// Shared score thresholds so the ring, chips and pins never disagree.
Color scoreColorFor(int score) {
  if (score >= 80) return AppColors.forest;
  if (score >= 50) return AppColors.blaze;
  return AppColors.alert;
}

String verdictFor(int score) {
  if (score >= 80) return "Safe to hike today";
  if (score >= 50) return "Hike with caution today";
  return "Not recommended today";
}

class Trail {
  final String name;
  final String region;
  final String difficulty; // Beginner | Intermediate | Advanced
  final String duration;
  final int safetyScore;
  final String weather;
  final String rainfallRisk;
  final String terrain;
  final double latitude;
  final double longitude;

  const Trail({
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.difficulty = "Intermediate",
    this.duration = "-",
    this.safetyScore = 75,
    this.weather = "Partly cloudy, 24C",
    this.rainfallRisk = "Low",
    this.terrain = "Moderate",
  });

  Color get scoreColor => scoreColorFor(safetyScore);
  String get verdict => verdictFor(safetyScore);

  /// 0 Beginner, 1 Intermediate, 2 Advanced.
  int get levelRank => switch (difficulty) {
        "Beginner" => 0,
        "Advanced" => 2,
        _ => 1,
      };

  /// A hiker can take on their own level and anything below it.
  bool suitsHiker(int hikerRank) => levelRank <= hikerRank;

  Color get levelColor => switch (levelRank) {
        0 => AppColors.forest,
        2 => AppColors.alert,
        _ => AppColors.blaze,
      };
}

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

/// The signed-in hiker. Filled from Firestore at login, cleared at logout.
class HikerProfile {
  static String fullName = "";
  static String email = "";
  static String emergencyContact = "";
  static String emergencyNumber = "";
  static String emergencyEmail = "";
  static String experienceLevel = "Intermediate Hiker";

  /// Local file path of the chosen photo. Null means fall back to initials.
  static String? photoPath;

  /// "Intermediate Hiker" becomes "Intermediate"
  static String get levelName =>
      experienceLevel.replaceAll(" Hiker", "").trim();

  static int get levelRank => switch (levelName) {
        "Beginner" => 0,
        "Advanced" => 2,
        _ => 1,
      };

  static String get initials {
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty || parts.first.isEmpty) return "?";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Wipes the signed-in hiker so the next person does not inherit it.
  static void signOut() {
    fullName = "";
    email = "";
    emergencyContact = "";
    emergencyNumber = "";
    emergencyEmail = "";
    experienceLevel = "Intermediate Hiker";
    photoPath = null;
  }
}

// ---------------------------------------------------------------------------
// Groups
// ---------------------------------------------------------------------------

/// A hiker in a group, as stored in Firestore. Coordinates are null until
/// that person starts a hike and their phone reports a position.
class GroupMember {
  final String name;
  final String email;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  const GroupMember({
    required this.name,
    required this.email,
    this.latitude,
    this.longitude,
    this.lastUpdated,
  });

  bool get isYou => email.toLowerCase() == HikerProfile.email.toLowerCase();

  bool get hasPosition => latitude != null && longitude != null;

  /// A position older than ten minutes is stale enough to flag.
  bool get isStale {
    final t = lastUpdated;
    if (t == null) return true;
    return DateTime.now().difference(t).inMinutes > 10;
  }
}

/// Tracks which group the hiker is currently in. The members themselves
/// come from Firestore, so this only holds the code and name.
class GroupSession {
  static String? code;
  static String name = "";

  static bool get isActive => code != null;

  static void setGroup({
    required String groupCode,
    required String groupName,
  }) {
    code = groupCode.toUpperCase();
    name = groupName;
  }

  static void clear() {
    code = null;
    name = "";
  }
}

/// A hazard report as stored in Firestore, for plotting on the map.
class HazardReport {
  final String id;
  final String type;
  final String description;
  final String nearestTrail;
  final double? latitude;
  final double? longitude;
  final String reportedByName;
  final DateTime? reportedAt;

  const HazardReport({
    required this.id,
    required this.type,
    required this.description,
    required this.nearestTrail,
    required this.reportedByName,
    this.latitude,
    this.longitude,
    this.reportedAt,
  });

  bool get hasPosition => latitude != null && longitude != null;

  /// Wildfire and landslide can kill; a missing sign is an inconvenience.
  AlertLevel get level {
    switch (type) {
      case "Wildfire":
      case "Landslide":
      case "Flooded trail":
        return AlertLevel.critical;
      case "Damaged bridge":
      case "Blocked path":
      case "Wildlife":
        return AlertLevel.caution;
      default:
        return AlertLevel.notice;
    }
  }

  Color get markerColor {
    switch (level) {
      case AlertLevel.critical:
        return AppColors.alert;
      case AlertLevel.caution:
        return AppColors.blaze;
      case AlertLevel.notice:
        return AppColors.inkSoft;
    }
  }

  IconData get icon {
    switch (type) {
      case "Fallen tree":
        return Icons.park_outlined;
      case "Flooded trail":
        return Icons.water_outlined;
      case "Wildfire":
        return Icons.local_fire_department_outlined;
      case "Landslide":
        return Icons.landslide_outlined;
      case "Blocked path":
        return Icons.block_outlined;
      case "Damaged bridge":
        return Icons.dangerous_outlined;
      case "Wildlife":
        return Icons.pets_outlined;
      case "Missing trail sign":
        return Icons.signpost_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String get ago {
    final t = reportedAt;
    if (t == null) return "just now";
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) {
      return "${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago";
    }
    return "${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago";
  }
}

/// One chat message in a group.
class GroupMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime? sentAt;

  const GroupMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.sentAt,
  });

  /// h:mm, since group chat is short-lived and the date rarely matters.
  String get timeLabel {
    final t = sentAt;
    if (t == null) return "";
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, "0");
    return "$hour:$minute ${t.hour < 12 ? "AM" : "PM"}";
  }
}

/// Stable colour per person, derived from their email, so the same hiker
/// looks the same to everyone in the group.
Color avatarColorFor(String seed) {
  const palette = [
    Color(0xFF1B7A4B),
    Color(0xFF2E6F9E),
    Color(0xFF8A4FBF),
    Color(0xFFC2632B),
    Color(0xFF0B7C7C),
    Color(0xFFA83E5B),
  ];
  if (seed.isEmpty) return palette.first;
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash + unit) % palette.length;
  }
  return palette[hash];
}













/// Hazards on one mountain over the last week, with a risk reading
/// derived from how many there are and how severe.
class TrailRisk {
  final String trailName;
  final List<HazardReport> reports;

  const TrailRisk({required this.trailName, required this.reports});

  int get criticalCount =>
      reports.where((r) => r.level == AlertLevel.critical).length;

  int get cautionCount =>
      reports.where((r) => r.level == AlertLevel.caution).length;

  /// The most recent report decides how current the picture is.
  DateTime? get latest {
    DateTime? newest;
    for (final r in reports) {
      final t = r.reportedAt;
      if (t == null) continue;
      if (newest == null || t.isAfter(newest)) newest = t;
    }
    return newest;
  }

  /// One critical report is enough to call a trail high risk. Several
  /// lesser ones together also add up.
  AlertLevel get level {
    if (criticalCount > 0) return AlertLevel.critical;
    if (cautionCount > 0 || reports.length >= 3) return AlertLevel.caution;
    return AlertLevel.notice;
  }

  String get verdict {
    switch (level) {
      case AlertLevel.critical:
        return "Avoid for now";
      case AlertLevel.caution:
        return "Go carefully";
      case AlertLevel.notice:
        return "Minor issues";
    }
  }

  Color get color {
    switch (level) {
      case AlertLevel.critical:
        return AppColors.alert;
      case AlertLevel.caution:
        return AppColors.blaze;
      case AlertLevel.notice:
        return AppColors.inkSoft;
    }
  }
}
