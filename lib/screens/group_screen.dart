import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "../data/hike_records.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../services/location_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";
import "group_chat_screen.dart";
import "group_setup_screens.dart";

const _distanceCalculator = Distance();

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _restoreGroup();
  }

  /// Puts the hiker back in whatever group they were in before the app
  /// was closed.
  Future<void> _restoreGroup() async {
    if (GroupSession.isActive) {
      setState(() => _restoring = false);
      return;
    }

    final code = await FirebaseService.savedGroupCode();
    if (!mounted) return;

    if (code != null) {
      final name = await FirebaseService.groupName(code);
      if (!mounted) return;
      if (name != null) {
        GroupSession.setGroup(groupCode: code, groupName: name);
      }
    }
    setState(() => _restoring = false);
  }

  Future<void> _openSetup(Widget screen) async {
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (joined == true && mounted) setState(() {});
  }

  /// Leaving is easy to hit by accident, so it always confirms first.
  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text("Leave this group?"),
        content: Text(
          "You will stop sharing your position with ${GroupSession.name}, "
          "and you will not see where the others are. You can rejoin with "
          "the code ${GroupSession.code}.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: Text("Stay in group"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: const Text("Leave group"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final code = GroupSession.code;
    if (code != null) await FirebaseService.leaveGroup(code);
    GroupSession.clear();

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You have left the group."),
        backgroundColor: AppColors.heroFill,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.forest),
      );
    }

    if (!GroupSession.isActive) {
      return _GroupEntryView(
        onCreate: () => _openSetup(const CreateGroupScreen()),
        onJoin: () => _openSetup(const JoinGroupScreen()),
      );
    }

    return _GroupLiveView(
      key: ValueKey(GroupSession.code),
      code: GroupSession.code!,
      onLeave: _confirmLeave,
    );
  }
}

// ---------------------------------------------------------------------------

class _GroupEntryView extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _GroupEntryView({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Group hiking",
                style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 6),
            Text("Keep track of each other on the trail.",
                style: Theme.of(context).textTheme.bodySmall),

            const Spacer(flex: 2),

            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups_outlined,
                    size: 44, color: AppColors.forest),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              "You are not in a group",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "Everyone in a group sees how far apart they are, so nobody "
              "gets left behind.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.55),
            ),

            const Spacer(flex: 3),

            PrimaryButton(
              label: "Create a group",
              icon: Icons.add_rounded,
              onPressed: onCreate,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: "Join a group",
              icon: Icons.login_rounded,
              onPressed: onJoin,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _GroupLiveView extends StatefulWidget {
  final String code;
  final VoidCallback onLeave;
  const _GroupLiveView({
    super.key,
    required this.code,
    required this.onLeave,
  });

  @override
  State<_GroupLiveView> createState() => _GroupLiveViewState();
}

class _GroupLiveViewState extends State<_GroupLiveView> {
  final _mapController = MapController();
  Timer? _pusher;
  bool _followMe = true;

  @override
  void initState() {
    super.initState();
    _pushPosition();
    // Every 8 seconds keeps the map current without burning quota.
    _pusher = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _pushPosition(),
    );
  }

  @override
  void dispose() {
    _pusher?.cancel();
    super.dispose();
  }

  /// Shares where this hiker is so the rest of the group can see them.
  Future<void> _pushPosition() async {
    double? lat = ActiveHike.latitude;
    double? lng = ActiveHike.longitude;

    // Not hiking, so take a one-off reading instead.
    if (lat == null || lng == null) {
      final position = await LocationService.currentPosition();
      lat = position?.latitude;
      lng = position?.longitude;
    }

    if (lat == null || lng == null || !mounted) return;

    await FirebaseService.updateMyPosition(
      code: widget.code,
      latitude: lat,
      longitude: lng,
    );

    if (_followMe && mounted) {
      _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
    }
  }

  double? _metresFromYou(GroupMember you, GroupMember other) {
    if (!you.hasPosition || !other.hasPosition) return null;
    return _distanceCalculator.as(
      LengthUnit.Meter,
      LatLng(you.latitude!, you.longitude!),
      LatLng(other.latitude!, other.longitude!),
    );
  }

  String _formatDistance(double metres) {
    if (metres < 1000) return "${metres.round()} m";
    return "${(metres / 1000).toStringAsFixed(1)} km";
  }

  Color _statusColor(double? metres) {
    if (metres == null) return AppColors.inkSoft;
    if (metres < 50) return AppColors.forest;
    if (metres < 500) return AppColors.blaze;
    return AppColors.alert;
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(
          code: widget.code,
          groupName: GroupSession.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<GroupMember>>(
        stream: FirebaseService.memberStream(widget.code),
        builder: (context, snapshot) {
          final members = snapshot.data ?? const <GroupMember>[];
          final loading =
              snapshot.connectionState == ConnectionState.waiting;

          GroupMember? you;
          for (final m in members) {
            if (m.isYou) you = m;
          }

          final sorted = [...members]..sort((a, b) {
              if (a.isYou) return -1;
              if (b.isYou) return 1;
              final da = you == null ? null : _metresFromYou(you, a);
              final db = you == null ? null : _metresFromYou(you, b);
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });

          final positioned = members.where((m) => m.hasPosition).toList();
          final centre = you != null && you.hasPosition
              ? LatLng(you.latitude!, you.longitude!)
              : positioned.isEmpty
                  ? null
                  : LatLng(
                      positioned.first.latitude!,
                      positioned.first.longitude!,
                    );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(GroupSession.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          SizedBox(height: 4),
                          Text(
                            "Code ${widget.code} - ${members.length} "
                            "${members.length == 1 ? "hiker" : "hikers"}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _openChat,
                      icon: Icon(Icons.forum_outlined,
                          color: AppColors.forest),
                      tooltip: "Group chat",
                    ),
                    IconButton(
                      onPressed: widget.onLeave,
                      icon: Icon(Icons.logout_rounded,
                          color: AppColors.alert),
                      tooltip: "Leave group",
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: AppRadius.card,
                    child: centre == null
                        ? Container(
                            color: AppColors.fill,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32),
                                child: Text(
                                  loading
                                      ? "Loading group..."
                                      : "No positions yet. Members appear "
                                          "once their phones report a "
                                          "location.",
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: centre,
                                  initialZoom: 15,
                                  // Panning by hand turns off following,
                                  // so the map does not fight the user.
                                  onPointerDown: (_, _) {
                                    if (_followMe) {
                                      setState(() => _followMe = false);
                                    }
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                    userAgentPackageName:
                                        "com.example.trailguard_ai",
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      for (final m in positioned)
                                        Marker(
                                          point: LatLng(
                                              m.latitude!, m.longitude!),
                                          width: 38,
                                          height: 38,
                                          child: _MemberPin(member: m),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Material(
                                  color: _followMe
                                      ? AppColors.forest
                                      : AppColors.card,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setState(() => _followMe = true);
                                      if (you != null && you.hasPosition) {
                                        _mapController.move(
                                          LatLng(
                                              you.latitude!, you.longitude!),
                                          16,
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(9),
                                      child: Icon(
                                        Icons.my_location_rounded,
                                        size: 20,
                                        color: _followMe
                                            ? Colors.white
                                            : AppColors.forest,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final m = sorted[i];
                    final metres =
                        you == null ? null : _metresFromYou(you, m);

                    final label = m.isYou
                        ? "You"
                        : !m.hasPosition
                            ? "No position"
                            : metres == null
                                ? "Unknown"
                                : metres < 50
                                    ? "Together"
                                    : "${_formatDistance(metres)} away";

                    return _MemberRow(
                      member: m,
                      label: label,
                      color:
                          m.isYou ? AppColors.forest : _statusColor(metres),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: "Group chat",
                        icon: Icons.forum_outlined,
                        onPressed: _openChat,
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Share code ${widget.code}"),
                              backgroundColor: AppColors.heroFill,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mist,
                          foregroundColor: AppColors.heroFill,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.pill),
                        ),
                        child: const Icon(Icons.person_add_alt_outlined,
                            size: 21),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Colour comes from the person's email, so the same hiker looks the same
/// to everyone in the group.
class _MemberPin extends StatelessWidget {
  final GroupMember member;
  const _MemberPin({required this.member});

  @override
  Widget build(BuildContext context) {
    final colour = member.isYou
        ? AppColors.pine
        : avatarColorFor(member.email);

    return Container(
      decoration: BoxDecoration(
        color: colour,
        shape: BoxShape.circle,
        border: Border.all(
          color: member.isStale && !member.isYou
              ? AppColors.blaze
              : Colors.white,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          member.name.isEmpty ? "?" : member.name[0].toUpperCase(),
          style: TextStyle(
            color: AppColors.onHero,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final GroupMember member;
  final String label;
  final Color color;

  const _MemberRow({
    required this.member,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colour = member.isYou
        ? AppColors.pine
        : avatarColorFor(member.email);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
            child: Center(
              child: Text(
                member.name.isEmpty ? "?" : member.name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onHero,
                ),
              ),
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.isYou ? "${member.name} (You)" : member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!member.isYou && member.hasPosition && member.isStale)
                  Text("Position may be out of date",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.blaze)),
              ],
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}













