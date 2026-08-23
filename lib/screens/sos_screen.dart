import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  // Three seconds of deliberate pressure, so a pocket tap can't fire it.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _sendSignal();
    });

  bool _sent = false;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _sendSignal() {
    setState(() => _sent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS sent. Location shared with your contact.'),
        backgroundColor: AppColors.alert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text('Emergency SOS',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 30),

                  Center(
                    child: GestureDetector(
                      onTapDown: (_) {
                        if (!_sent) _hold.forward();
                      },
                      onTapUp: (_) => _hold.reverse(),
                      onTapCancel: () => _hold.reverse(),
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
                                    value: _hold.value,
                                    strokeWidth: 8,
                                    backgroundColor: AppColors.fill,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
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
                                      const SizedBox(height: 8),
                                      Text(
                                        _sent ? 'SOS sent' : 'Hold to SOS',
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
                  const SizedBox(height: 28),

                  Text(
                    _sent
                        ? 'Your GPS position is being shared with your emergency contact and the nearest ranger station. Stay where you are if it is safe.'
                        : 'Hold the button for 3 seconds to share your GPS position with your emergency contact and the nearest ranger station.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.55, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 30),

                  const _InfoRow(
                    icon: Icons.my_location_rounded,
                    label: 'Current location',
                    value: '14.2 km from trailhead',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.person_pin_circle_outlined,
                    label: 'Emergency contact',
                    value: HikerProfile.emergencyContact,
                  ),
                  const SizedBox(height: 10),
                  const _InfoRow(
                    icon: Icons.cabin_outlined,
                    label: 'Nearest ranger station',
                    value: 'Kapatagan Post · 6.8 km',
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