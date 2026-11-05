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

/// Someone with no hike running is judged on distance instead of mountain
/// name. Twenty kilometres is generous enough for different trailheads on
/// the same massif, tight enough to exclude someone still in town.
const double _sameAreaMetres = 20000;

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

  /// Deletes the group for everyone, permanently. Only the creator ever
  /// sees the button that reaches this.
  Future<void> _confirmDelete() async {
    final code = GroupSession.code;
    if (code == null) return;
    final name = GroupSession.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text("Delete this group?"),
        content: Text(
          "This removes $name for everyone in it, along with the chat, the "
          "shared photos and every member's position. It cannot be undone, "
          "and the code $code will stop working.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: Text("Keep group"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: const Text("Delete forever"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await FirebaseService.deleteGroup(code);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.alert,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name was deleted."),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      onDelete: _confirmDelete,
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
  final VoidCallback onDelete;
  const _GroupLiveView({
    super.key,
    required this.code,
    required this.onLeave,
    required this.onDelete,
  });

  @override
  State<_GroupLiveView> createState() => _GroupLiveViewState();
}

class _GroupLiveViewState extends State<_GroupLiveView> {
  final _mapController = MapController();
  Timer? _pusher;
  bool _followMe = true;
  bool _mapReady = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
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

  /// The delete button only exists for whoever created the group, so the
  /// answer is needed before the header is drawn.
  Future<void> _checkAdmin() async {
    final admin = await FirebaseService.isGroupAdmin(widget.code);
    if (!mounted) return;
    setState(() => _isAdmin = admin);
  }

  /// Shares where this hiker is so the rest of the group can see them.
  /// The mountain goes up with it, which is what lets the map keep the
  /// group together instead of zooming out across the island.
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
      trailName: ActiveHike.trail?.name,
    );

    if (_followMe && _mapReady && mounted) {
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

  /// Everyone who is plausibly on the same mountain as you.
  ///
  /// A member reporting the same trail name is in, full stop. A member with
  /// no hike running has no trail name, so they are kept only if they are
  /// close enough to be on the same massif. Anyone else is somewhere else
  /// entirely and would only drag the map off the trail.
  List<GroupMember> _onYourMountain(
    List<GroupMember> positioned,
    GroupMember? you,
  ) {
    final String? yourMountain = ActiveHike.trail?.name ?? you?.trailName;
    final keep = <GroupMember>[];

    for (final m in positioned) {
      if (m.isYou) {
        keep.add(m);
        continue;
      }

      if (yourMountain != null && m.trailName != null) {
        if (m.trailName == yourMountain) keep.add(m);
        continue;
      }

      final d = you == null ? null : _metresFromYou(you, m);
      if (d == null || d <= _sameAreaMetres) keep.add(m);
    }

    return keep;
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

  void _focusOn(GroupMember m) {
    if (!m.hasPosition || !_mapReady) return;
    setState(() => _followMe = false);
    _mapController.move(LatLng(m.latitude!, m.longitude!), 16);
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

          final emergencies =
              members.where((m) => m.sosActive && !m.isYou).toList();
          final yourOwnSos = you != null && you.sosActive;

          final positioned = members.where((m) => m.hasPosition).toList();
          final onMountain = _onYourMountain(positioned, you);

          // An emergency is drawn wherever it is. If somebody is in trouble
          // on another mountain you still want to see them.
          final visible = <GroupMember>[
            ...onMountain,
            ...positioned
                .where((m) => m.sosActive && !onMountain.contains(m)),
          ];
          final hiddenCount = positioned.length - visible.length;

          // Sort: emergencies first, then you, then nearest.
          final sorted = [...members]..sort((a, b) {
              if (a.sosActive != b.sosActive) return a.sosActive ? -1 : 1;
              if (a.isYou) return -1;
              if (b.isYou) return 1;
              final da = you == null ? null : _metresFromYou(you, a);
              final db = you == null ? null : _metresFromYou(you, b);
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });

          // The map opens on the emergency if there is one.
          GroupMember? focus;
          for (final m in visible) {
            if (m.sosActive) {
              focus = m;
              break;
            }
          }

          LatLng? centre;
          if (focus != null) {
            centre = LatLng(focus.latitude!, focus.longitude!);
          } else if (you != null && you.hasPosition) {
            centre = LatLng(you.latitude!, you.longitude!);
          } else if (visible.isNotEmpty) {
            centre =
                LatLng(visible.first.latitude!, visible.first.longitude!);
          }

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
                    if (_isAdmin)
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: Icon(Icons.delete_outline_rounded,
                            color: AppColors.alert),
                        tooltip: "Delete group",
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

              // The emergency banner sits above everything. Nothing else on
              // this screen matters while somebody is in trouble.
              if (emergencies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _EmergencyBanner(
                    members: emergencies,
                    onFocus: _focusOn,
                  ),
                ),

              if (yourOwnSos)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _YourSosBanner(),
                ),

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
                                      : hiddenCount > 0
                                          ? "Nobody from this group is on "
                                              "your mountain yet."
                                          : "No positions yet. Members "
                                              "appear once their phones "
                                              "report a location.",
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
                                  onMapReady: () {
                                    if (!_mapReady) _mapReady = true;
                                  },
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
                                      for (final m in visible)
                                        Marker(
                                          point: LatLng(
                                              m.latitude!, m.longitude!),
                                          width: m.sosActive ? 48 : 38,
                                          height: m.sosActive ? 48 : 38,
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
                                      if (you != null &&
                                          you.hasPosition &&
                                          _mapReady) {
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

              if (hiddenCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined,
                          size: 14, color: AppColors.inkSoft),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "$hiddenCount ${hiddenCount == 1 ? "hiker is" : "hikers are"} "
                          "on another mountain and not shown on the map.",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
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

                    final label = m.sosActive
                        ? "EMERGENCY"
                        : m.isYou
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
                      color: m.sosActive
                          ? AppColors.alert
                          : m.isYou
                              ? AppColors.forest
                              : _statusColor(metres),
                      onTap: m.hasPosition ? () => _focusOn(m) : null,
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

/// Red banner naming whoever is in trouble, with a tap to centre the map
/// on them.
class _EmergencyBanner extends StatelessWidget {
  final List<GroupMember> members;
  final void Function(GroupMember) onFocus;

  const _EmergencyBanner({required this.members, required this.onFocus});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.alert,
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sos_rounded, size: 22, color: Colors.white),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    members.length == 1
                        ? "${members.first.name} needs help"
                        : "${members.length} hikers need help",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final m in members)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.hasPosition
                            ? "${m.name} - SOS ${m.sosAgo}"
                            : "${m.name} - SOS ${m.sosAgo}, no position",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    if (m.hasPosition)
                      TextButton(
                        onPressed: () => onFocus(m),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Show on map"),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reminder that your own SOS is still open, so it does not sit forgotten.
class _YourSosBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14B3261E),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.alert, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.alert),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your SOS is still open. Open the SOS screen and mark "
              "yourself safe once you no longer need help.",
              style: TextStyle(fontSize: 12.5, color: AppColors.alert),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colour comes from the person's email, so the same hiker looks the same
/// to everyone in the group. An open SOS overrides it with red.
class _MemberPin extends StatelessWidget {
  final GroupMember member;
  const _MemberPin({required this.member});

  @override
  Widget build(BuildContext context) {
    if (member.sosActive) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.alert,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
        ),
        child: Center(
          child: Icon(
            Icons.priority_high_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      );
    }

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
  final VoidCallback? onTap;

  const _MemberRow({
    required this.member,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emergency = member.sosActive;
    final colour = emergency
        ? AppColors.alert
        : member.isYou
            ? AppColors.pine
            : avatarColorFor(member.email);

    final card = AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
            child: Center(
              child: emergency
                  ? Icon(Icons.priority_high_rounded,
                      size: 20, color: Colors.white)
                  : Text(
                      member.name.isEmpty
                          ? "?"
                          : member.name[0].toUpperCase(),
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
                if (emergency)
                  Text(
                    member.hasPosition
                        ? "SOS raised ${member.sosAgo}"
                        : "SOS raised ${member.sosAgo}, no position",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.alert),
                  )
                else if (!member.isYou &&
                    member.hasPosition &&
                    member.isStale)
                  Text("Position may be out of date",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.blaze))
                else if (!member.isYou && member.trailName != null)
                  Text(member.trailName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
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

    if (onTap == null) return card;

    return InkWell(
      borderRadius: AppRadius.card,
      onTap: onTap,
      child: card,
    );
  }
}
