import "package:flutter/material.dart";
import "../data/hike_records.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";
import "achievements_screen.dart";
import "delete_account_screen.dart";
import "edit_profile_screen.dart";
import "welcome_screen.dart";

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) setState(() {});
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text("Log out?"),
        content: Text(
          ActiveHike.isActive
              ? "You have a hike in progress. Logging out will discard it "
                  "without saving."
              : "Your hikes and profile are saved. Log back in any time to "
                  "pick up where you left off.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: Text("Stay signed in"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: Text("Log out"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await FirebaseService.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = HikeLog.totalTime.inHours;
    final minutes = HikeLog.totalTime.inMinutes.remainder(60);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Center(child: ProfileAvatar(photoPath: HikerProfile.photoPath)),
          SizedBox(height: 16),
          Center(
            child: Text(HikerProfile.fullName,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                // Only the level word is translated; the stored value
                // stays English so scoring keeps working.
                "${HikerProfile.levelName} ${"Hiker"}",
                style: TextStyle(
                  color: AppColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
              child: SecondaryButton(
                label: "Edit profile",
                icon: Icons.edit_outlined,
                onPressed: () => _push(const EditProfileScreen()),
              ),
            ),
          ),

          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: "Hikes completed",
                  value: "${HikeLog.totalHikes}",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: "Distance",
                  value: "${HikeLog.totalKm.toStringAsFixed(1)} km",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: "Time on trail",
                  value: hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m",
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: "Badges",
                  value: "${HikeLog.earnedBadgeCount}",
                ),
              ),
            ],
          ),

          SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            onTap: () => _push(const AchievementsScreen()),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: AppRadius.field,
                  ),
                  child: Icon(Icons.emoji_events_outlined,
                      size: 22, color: AppColors.forest),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("View achievements",
                          style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 2),
                      Text(
                        HikeLog.totalHikes == 0
                            ? "No hikes yet"
                            : "${HikeLog.uniqueMountains.length} "
                                "${"Mountains climbed".toLowerCase()} - "
                                "${HikeLog.earnedBadgeCount} "
                                "${"Badges".toLowerCase()}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.inkSoft),
              ],
            ),
          ),

          SizedBox(height: 28),
          SectionLabel("Account"),
          SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _AccountRow(
                  icon: Icons.mail_outline_rounded,
                  label: "Email",
                  trailing: HikerProfile.email,
                ),
                Divider(height: 1, color: AppColors.line),
                _AccountRow(
                  icon: Icons.person_pin_circle_outlined,
                  label: "Emergency contact",
                  trailing: HikerProfile.emergencyContact,
                ),
                Divider(height: 1, color: AppColors.line),
                _AccountRow(
                  icon: Icons.alternate_email_rounded,
                  label: "Contact Gmail",
                  trailing: HikerProfile.emergencyEmail,
                ),
                Divider(height: 1, color: AppColors.line),
                _AccountRow(
                  icon: Icons.phone_outlined,
                  label: "Contact number",
                  trailing: HikerProfile.emergencyNumber,
                ),
                Divider(height: 1, color: AppColors.line),

                // Tappable, so the language can be changed without
                // hunting through settings.
                _AccountRow(
                  icon: Icons.download_outlined,
                  label: "Offline maps",
                  trailing: "None saved",
                ),
              ],
            ),
          ),

          SizedBox(height: 24),
          // Sits above Log out and styled identically in red, so the two
          // destructive actions read as a pair rather than one hiding.
          SecondaryButton(
            label: "Delete account",
            icon: Icons.delete_outline_rounded,
            color: AppColors.alert,
            onPressed: () => _push(const DeleteAccountScreen()),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: "Log out",
            icon: Icons.logout_rounded,
            color: AppColors.alert,
            onPressed: _logOut,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "TrailGuard Mindanao - Version 1.0.0",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.inkSoft),
          SizedBox(width: 13),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Flexible(
            child: Text(
              trailing.isEmpty ? "-" : trailing,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),        ],
      ),
    );
  }
}




















