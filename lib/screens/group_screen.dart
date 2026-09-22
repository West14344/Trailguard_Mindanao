import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'group_setup_screens.dart';

const _distanceCalculator = Distance();

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  Future<void> _openSetup(Widget screen) async {
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (joined == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!GroupSession.isActive) {
      return _GroupEntryView(
        onCreate: () => _openSetup(const CreateGroupScreen()),
        onJoin: () => _openSetup(const JoinGroupScreen()),
      );
    }
    return _GroupLiveView(
      key: ValueKey(GroupSession.code),
      onLeave: () => setState(GroupSession.leave),
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
            Text('Group hiking',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Keep track of each other on the trail.',
                style: Theme.of(context).textTheme.bodySmall),

            const Spacer(flex: 2),

            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_outlined,
                    size: 44, color: AppColors.forest),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              "You're not in a group",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Everyone in a group sees how far apart they are, so nobody '
              'gets left behind.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.55),
            ),

            const Spacer(flex: 3),

            PrimaryButton(
              label: 'Create a group',
              icon: Icons.add_rounded,
              onPressed: onCreate,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Join a group',
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
  final VoidCallback onLeave;
  const _GroupLiveView({super.key, required this.onLeave});

  @override
  State<_GroupLiveView> createState() => _GroupLiveViewState();
}

class _GroupLiveViewState extends State<_GroupLiveView> {
  Timer? _ticker;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Nudges other members so distances visibly update. Replace with a
    // position stream from the backend when one exists.
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        for (final m in GroupSession.members) {
          if (m.isYou) continue;
          m.latitude += (_random.nextDouble() - 0.5) * 0.0004;
          m.longitude += (_random.nextDouble() - 0.5) * 0.0004;
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  GroupMember? get _you {
    for (final m in GroupSession.members) {
      if (m.isYou) return m;
    }
    return null;
  }

  double _metersFromYou(GroupMember member) {
    final you = _you;
    if (you == null || member.isYou) return 0;
    return _distanceCalculator.as(
      LengthUnit.Meter,
      LatLng(you.latitude, you.longitude),
      LatLng(member.latitude, member.longitude),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Color _statusColor(double meters) {
    if (meters < 50) return AppColors.forest;
    if (meters < 500) return AppColors.blaze;
    return AppColors.alert;
  }

  @override
  Widget build(BuildContext context) {
    final members = GroupSession.members;
    final you = _you;

    if (members.isEmpty || you == null) {
      return _WaitingForHikers(onLeave: widget.onLeave);
    }

    final sorted = [...members]
      ..sort((a, b) => _metersFromYou(a).compareTo(_metersFromYou(b)));
    final furthest = _metersFromYou(sorted.last);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(GroupSession.name,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Code ${GroupSession.code} · ${members.length} '
                        '${members.length == 1 ? "hiker" : "hikers"}'
                        '${members.length > 1 ? " · spread ${_formatDistance(furthest)}" : ""}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onLeave,
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.inkSoft),
                  tooltip: 'Leave group',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 186,
              child: ClipRRect(
                borderRadius: AppRadius.card,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(you.latitude, you.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.trailguard_ai',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final m in members)
                          Marker(
                            point: LatLng(m.latitude, m.longitude),
                            width: 34,
                            height: 34,
                            child: _MemberPin(
                              initial: m.name.isEmpty ? '?' : m.name[0],
                              isYou: m.isYou,
                              color: m.isYou
                                  ? AppColors.pine
                                  : _statusColor(_metersFromYou(m)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final m in sorted) ...[
                  _MemberRow(
                    member: m,
                    label: m.isYou
                        ? 'You'
                        : _metersFromYou(m) < 50
                            ? 'Together'
                            : '${_formatDistance(_metersFromYou(m))} away',
                    color: m.isYou
                        ? AppColors.forest
                        : _statusColor(_metersFromYou(m)),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SecondaryButton(
              label: 'Invite hiker',
              icon: Icons.person_add_alt_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share code ${GroupSession.code}'),
                    backgroundColor: AppColors.pine,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _WaitingForHikers extends StatelessWidget {
  final VoidCallback onLeave;
  const _WaitingForHikers({required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(GroupSession.name,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Code ${GroupSession.code}',
                style: Theme.of(context).textTheme.bodySmall),

            const Spacer(),

            Center(
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: AppColors.mist,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_search_outlined,
                        size: 42, color: AppColors.forest),
                  ),
                  const SizedBox(height: 20),
                  Text('Waiting for hikers to join',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Share the code and everyone\'s distance from you appears '
                    'here as they join.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.55),
                  ),
                ],
              ),
            ),

            const Spacer(),

            PrimaryButton(
              label: 'Share code ${GroupSession.code}',
              icon: Icons.ios_share_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invite code ${GroupSession.code} copied'),
                    backgroundColor: AppColors.pine,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Leave group',
              icon: Icons.logout_rounded,
              color: AppColors.alert,
              onPressed: onLeave,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MemberPin extends StatelessWidget {
  final String initial;
  final bool isYou;
  final Color color;

  const _MemberPin({
    required this.initial,
    required this.isYou,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Center(
        child: Text(
          isYou ? '●' : initial.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
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
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: member.isYou ? AppColors.pine : AppColors.fill,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: member.isYou ? AppColors.moss : AppColors.forest,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              member.isYou ? '${member.name} (You)' : member.name,
              style: Theme.of(context).textTheme.titleMedium,
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