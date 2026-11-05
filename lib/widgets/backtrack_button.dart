import 'package:flutter/material.dart';

import '../screens/backtrack_screen.dart';
import '../services/breadcrumb_trail.dart';
import '../theme/app_theme.dart';

/// Opens the breadcrumb Backtrack screen.
///
/// Shows the live crumb count, so you can tell at a glance whether the
/// trail is actually recording.
class BacktrackButton extends StatelessWidget {
  final bool compact;

  const BacktrackButton({super.key, this.compact = false});

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const BacktrackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Backtrack to the trailhead',
        icon: Icon(Icons.u_turn_left_rounded, color: AppColors.ink),
        onPressed: () => _open(context),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: BreadcrumbTrail.revision,
      builder: (BuildContext context, int _, Widget? _) {
        final int crumbs = BreadcrumbTrail.pointCount;
        final String subtitle = crumbs == 0
            ? 'no breadcrumbs yet - keep moving'
            : '$crumbs breadcrumbs - '
                '${BreadcrumbTrail.formatDistance(BreadcrumbTrail.walkedMetres)} '
                'of trail recorded';

        return Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.pine, width: 1.4),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(context),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: <Widget>[
                  Icon(Icons.u_turn_left_rounded,
                      size: 22, color: AppColors.pine),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Backtrack',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: AppColors.pine),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}