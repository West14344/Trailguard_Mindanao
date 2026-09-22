import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared score thresholds so the ring, chips and pins never disagree.
Color scoreColorFor(int score) {
  if (score >= 80) return AppColors.forest;
  if (score >= 50) return AppColors.blaze;
  return AppColors.alert;
}

String verdictFor(int score) {
  if (score >= 80) return 'Safe to hike today';
  if (score >= 50) return 'Hike with caution today';
  return 'Not recommended today';
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
    this.difficulty = 'Intermediate',
    this.duration = '—',
    this.safetyScore = 75,
    this.weather = 'Partly cloudy, 24°C',
    this.rainfallRisk = 'Low',
    this.terrain = 'Moderate',
  });

  Color get scoreColor => scoreColorFor(safetyScore);
  String get verdict => verdictFor(safetyScore);

  /// 0 Beginner, 1 Intermediate, 2 Advanced.
  int get levelRank => switch (difficulty) {
        'Beginner' => 0,
        'Advanced' => 2,
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

/// Populated by the hazard-report and weather services once a backend exists.
const kAlerts = <TrailAlert>[];

/// Single source of truth for the signed-in hiker while there is no backend.
class HikerProfile {
  static String fullName = '';
  static String email = '';
  static String emergencyContact = '';
  static String emergencyNumber = '';
  static String experienceLevel = 'Intermediate Hiker';

  /// Local file path of the chosen photo. Null means fall back to initials.
  static String? photoPath;

  /// "Intermediate Hiker" → "Intermediate"
  static String get levelName =>
      experienceLevel.replaceAll(' Hiker', '').trim();

  static int get levelRank => switch (levelName) {
        'Beginner' => 0,
        'Advanced' => 2,
        _ => 1,
      };

  static String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Wipes the signed-in hiker. Called on logout so the next person to
  /// use the device does not inherit this one's details.
  static void signOut() {
    fullName = '';
    email = '';
    emergencyContact = '';
    emergencyNumber = '';
    experienceLevel = 'Intermediate Hiker';
    photoPath = null;
  }
}

// ---------------------------------------------------------------------------
// Groups
// ---------------------------------------------------------------------------

/// A hiker in a group. Positions are held here so distance between members
/// is computed rather than stored, staying correct as people move.
class GroupMember {
  final String name;
  final String email;
  double latitude;
  double longitude;

  GroupMember({
    required this.name,
    required this.email,
    required this.latitude,
    required this.longitude,
  });

  bool get isYou => email.toLowerCase() == HikerProfile.email.toLowerCase();
}

/// One group, keyed by its share code.
class TrailGroup {
  final String name;
  final String code;
  final List<GroupMember> members;

  TrailGroup({
    required this.name,
    required this.code,
    required this.members,
  });
}

/// Stand-in for a groups table. Lives in memory on this device, so codes
/// validate against real groups but cannot be seen by another phone.
/// Replace with Firebase Realtime Database for true multi-device sync.
class GroupRegistry {
  static final Map<String, TrailGroup> _groups = {};

  /// Trailhead the group starts from. Members are seeded near this point.
  static const _anchorLat = 6.9875;
  static const _anchorLng = 125.2731;

  static bool exists(String code) => _groups.containsKey(code.toUpperCase());

  static TrailGroup? find(String code) => _groups[code.toUpperCase()];

  /// Creates a group with the current hiker as its first member.
  static TrailGroup create({required String name, required String code}) {
    final group = TrailGroup(
      name: name,
      code: code.toUpperCase(),
      members: [_memberForCurrentHiker(0)],
    );
    _groups[group.code] = group;
    return group;
  }

  /// Adds the current hiker to an existing group. Returns null when the
  /// code matches nothing.
  static TrailGroup? join(String code) {
    final group = _groups[code.toUpperCase()];
    if (group == null) return null;

    final already = group.members.any(
        (m) => m.email.toLowerCase() == HikerProfile.email.toLowerCase());

    if (!already) {
      group.members.add(_memberForCurrentHiker(group.members.length));
    }
    return group;
  }

  /// Spreads members out along the trail so the map is readable.
  static GroupMember _memberForCurrentHiker(int index) {
    return GroupMember(
      name: HikerProfile.fullName.isEmpty ? 'Hiker' : HikerProfile.fullName,
      email: HikerProfile.email,
      latitude: _anchorLat + (index * 0.0012),
      longitude: _anchorLng + (index * 0.0009),
    );
  }

  static void leave(String code) {
    final group = _groups[code.toUpperCase()];
    group?.members.removeWhere(
        (m) => m.email.toLowerCase() == HikerProfile.email.toLowerCase());
    if (group != null && group.members.isEmpty) {
      _groups.remove(group.code);
    }
  }
}

/// Tracks which group the hiker is currently in.
class GroupSession {
  static TrailGroup? current;

  static bool get isActive => current != null;
  static String get name => current?.name ?? '';
  static String get code => current?.code ?? '';
  static List<GroupMember> get members => current?.members ?? const [];

  static void setGroup(TrailGroup group) => current = group;

  static void leave() {
    final group = current;
    if (group != null) GroupRegistry.leave(group.code);
    current = null;
  }
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

/// Stand-in for a user table. Holds accounts in memory for the session, so
/// signing up and logging back in works without a backend. Replace with
/// Firebase Auth or an API call when one exists.
class AccountStore {
  static final Map<String, _Account> _accounts = {};

  static void register({
    required String email,
    required String password,
    required String fullName,
    required String emergencyContact,
    required String emergencyNumber,
  }) {
    _accounts[email.toLowerCase()] = _Account(
      password: password,
      fullName: fullName,
      emergencyContact: emergencyContact,
      emergencyNumber: emergencyNumber,
    );
  }

  static bool emailExists(String email) =>
      _accounts.containsKey(email.toLowerCase());

  /// Loads the account into HikerProfile when the password matches.
  static bool signIn({required String email, required String password}) {
    final account = _accounts[email.toLowerCase()];
    if (account == null || account.password != password) return false;

    HikerProfile.fullName = account.fullName;
    HikerProfile.email = email.toLowerCase();
    HikerProfile.emergencyContact = account.emergencyContact;
    HikerProfile.emergencyNumber = account.emergencyNumber;
    HikerProfile.experienceLevel = account.experienceLevel;
    HikerProfile.photoPath = account.photoPath;
    return true;
  }

  /// Keeps the stored account in step with profile edits.
  static void syncFromProfile() {
    final account = _accounts[HikerProfile.email.toLowerCase()];
    if (account == null) return;
    account.fullName = HikerProfile.fullName;
    account.emergencyContact = HikerProfile.emergencyContact;
    account.emergencyNumber = HikerProfile.emergencyNumber;
    account.experienceLevel = HikerProfile.experienceLevel;
    account.photoPath = HikerProfile.photoPath;
  }

  static bool get hasAnyAccount => _accounts.isNotEmpty;
}

class _Account {
  final String password;
  String fullName;
  String emergencyContact;
  String emergencyNumber;
  String experienceLevel;
  String? photoPath;

  _Account({
    required this.password,
    required this.fullName,
    required this.emergencyContact,
    required this.emergencyNumber,
    this.experienceLevel = 'Intermediate Hiker',
    this.photoPath,
  });
}