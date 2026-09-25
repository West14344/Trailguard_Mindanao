import "dart:async";

import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "../data/hike_records.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../services/location_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  // Three seconds of deliberate pressure, so a pocket tap cannot fire it.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _sendSignal();
    });

  Position? _position;
  String? _locationError;
  bool _findingLocation = true;

  bool _sending = false;
  bool _sent = false;
  String? _eventId;
  DateTime? _sentAt;
  String? _sendError;

  Timer? _positionRefresh;

  @override
  void initState() {
    super.initState();
    _findLocation();
  }

  @override
  void dispose() {
    _hold.dispose();
    _positionRefresh?.cancel();
    super.dispose();
  }

  /// Fetched on open, not on press: in an emergency the position should
  /// already be known by the time the button is held.
  Future<void> _findLocation() async {
    final error = await LocationService.ensurePermission();
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _locationError = error;
        _findingLocation = false;
      });
      return;
    }

    final position = await LocationService.currentPosition();
    if (!mounted) return;

    setState(() {
      _position = position;
      _findingLocation = false;
      if (position == null) {
        _locationError =
            "Could not get a GPS fix. Move to open sky and try again.";
      }
    });
  }

  Future<void> _sendSignal() async {
    if (_sending || _sent) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });

    final eventId = await FirebaseService.recordSos(
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      accuracyM: _position?.accuracy,
      trailName: ActiveHike.trail?.name,
    );

    if (!mounted) return;

    if (eventId == null) {
      setState(() {
        _sending = false;
        _sendError = "Could not reach the server. Try again, or call your "
            "emergency contact directly.";
      });
      _hold.reset();
      return;
    }

    setState(() {
      _sending = false;
      _sent = true;
      _eventId = eventId;
      _sentAt = DateTime.now();
    });

    // Keep the recorded position current while the emergency is open.
    _positionRefresh = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshPosition(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_position == null
            ? "SOS recorded without a position. Move to open sky if you can."
            : "SOS recorded. Your location has been shared."),
        backgroundColor: AppColors.alert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshPosition() async {
    final id = _eventId;
    if (id == null) return;

    final position = await LocationService.currentPosition();
    if (position == null || !mounted) return;

    setState(() => _position = position);
    await FirebaseService.updateSosPosition(
      eventId: id,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _markSafe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text("Mark yourself safe?"),
        content: Text(
          "This closes the emergency. Only do this if you no longer need "
          "help.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.forest),
            child: const Text("I am safe"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final id = _eventId;
    if (id != null) await FirebaseService.resolveSos(id);

    _positionRefresh?.cancel();
    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Emergency closed. Glad you are safe."),
        backgroundColor: AppColors.pine,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _coordinates {
    final p = _position;
    if (p == null) return "Unavailable";
    return "${p.latitude.toStringAsFixed(5)}, "
        "${p.longitude.toStringAsFixed(5)}";
  }

  String get _accuracy {
    final p = _position;
    if (p == null) return "No fix";
    return "Accurate to ${p.accuracy.round()} m";
  }

  String get _sentAgo {
    final t = _sentAt;
    if (t == null) return "";
    final mins = DateTime.now().difference(t).inMinutes;
    if (mins < 1) return "Sent just now";
    return "Sent $mins ${mins == 1 ? "minute" : "minutes"} ago";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving mid-emergency by accident would be bad, so confirm first.
      canPop: !_sent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _sent) _markSafe();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _sending
                          ? null
                          : () {
                              if (_sent) {
                                _markSafe();
                              } else {
                                Navigator.of(context).maybePop();
                              }
                            },
                      icon: Icon(Icons.arrow_back, size: 20),
                      label: Text("Back"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  children: [
                    Text("Emergency SOS",
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 26),

                    Center(
                      child: GestureDetector(
                        onTapDown: (_) {
                          if (!_sent && !_sending) _hold.forward();
                        },
                        onTapUp: (_) {
                          if (!_sent) _hold.reverse();
                        },
                        onTapCancel: () {
                          if (!_sent) _hold.reverse();
                        },
                        child: AnimatedBuilder(
                          animation: _hold,
                          builder: (context, _) {
                            return SizedBox(
                              width: 210,
                              height: 210,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 210,
                                    height: 210,
                                    child: CircularProgressIndicator(
                                      value: _sending ? null : _hold.value,
                                      strokeWidth: 8,
                                      backgroundColor: AppColors.fill,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              AppColors.alert),
                                    ),
                                  ),
                                  Container(
                                    width: 178,
                                    height: 178,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _sent
                                          ? AppColors.alert
                                          : const Color(0x14B3261E),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _sent
                                              ? Icons.check_rounded
                                              : Icons.call_rounded,
                                          size: 46,
                                          color: _sent
                                              ? Colors.white
                                              : AppColors.alert,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _sending
                                              ? "Sending..."
                                              : _sent
                                                  ? "SOS active"
                                                  : "Hold to SOS",
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: _sent
                                                ? Colors.white
                                                : AppColors.alert,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_sent)
                      Center(
                        child: Text(_sentAgo,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    SizedBox(height: 10),

                    Text(
                      _sent
                          ? "Your emergency has been recorded with your "
                              "position, and it updates every 30 seconds "
                              "while this screen is open. Stay where you "
                              "are if it is safe."
                          : "Hold the button for 3 seconds to record an "
                              "emergency with your GPS position and "
                              "emergency contact details.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.55, color: AppColors.inkSoft),
                    ),

                    if (_sendError != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x14B3261E),
                          borderRadius: AppRadius.field,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline,
                                size: 17, color: AppColors.alert),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _sendError!,
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.alert),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 28),

                    if (_findingLocation)
                      _InfoRow(
                        icon: Icons.my_location_rounded,
                        label: "Your position",
                        value: "Finding GPS...",
                      )
                    else if (_locationError != null)
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_off_outlined,
                                size: 20, color: AppColors.blaze),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_locationError!,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _findingLocation = true);
                                _findLocation();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.forest,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _InfoRow(
                        icon: Icons.my_location_rounded,
                        label: "Your position",
                        value: _coordinates,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.gps_fixed_rounded,
                        label: "GPS accuracy",
                        value: _accuracy,
                      ),
                    ],

                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.person_pin_circle_outlined,
                      label: "Emergency contact",
                      value: HikerProfile.emergencyContact.isEmpty
                          ? "Not set"
                          : HikerProfile.emergencyContact,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: "Contact number",
                      value: HikerProfile.emergencyNumber.isEmpty
                          ? "Not set"
                          : HikerProfile.emergencyNumber,
                    ),
                    if (ActiveHike.trail != null) ...[
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.terrain_rounded,
                        label: "Trail",
                        value: ActiveHike.trail!.name,
                      ),
                    ],

                    if (_sent) ...[
                      const SizedBox(height: 26),
                      SecondaryButton(
                        label: "I am safe now",
                        icon: Icons.check_circle_outline,
                        onPressed: _markSafe,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.alert),
          const SizedBox(width: 13),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}











