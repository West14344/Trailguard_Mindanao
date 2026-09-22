import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'hazard_report_screen.dart';
import 'sos_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerts',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  kAlerts.isEmpty
                      ? 'Nothing to report right now'
                      : '${kAlerts.length} active near your saved trails',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          Expanded(
            child: kAlerts.isEmpty
                ? const _NoAlerts()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    children: [
                      for (final alert in kAlerts) ...[
                        _AlertCard(alert: alert),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Emergency SOS',
                  icon: Icons.sos_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SosScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: 'Report a hazard',
                  icon: Icons.flag_outlined,
                  color: AppColors.blaze,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const HazardReportScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet reassurance rather than an error — no alerts is good news.
class _NoAlerts extends StatelessWidget {
  const _NoAlerts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 42, color: AppColors.forest),
            ),
            const SizedBox(height: 20),
            Text('All clear',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Weather warnings and hazards reported by other hikers show up '
              'here. You will be notified as soon as one appears.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colour comes from the alert's own level, so severity reads at a glance.
class _AlertCard extends StatelessWidget {
  final TrailAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: alert.background,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: alert.level == AlertLevel.notice
              ? AppColors.line
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(alert.icon, color: alert.foreground, size: 24),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    color: alert.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.detail,
                  style: TextStyle(
                    color: alert.level == AlertLevel.notice
                        ? AppColors.inkSoft
                        : const Color(0xE6FFFFFF),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}