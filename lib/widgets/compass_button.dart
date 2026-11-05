import 'package:flutter/material.dart';

import '../screens/compass_screen.dart';
import '../theme/app_theme.dart';

/// Opens the offline compass.
///
/// Drop `const CompassButton()` into any Row or Column, or
/// `const CompassButton(compact: true)` into an AppBar's actions list.
class CompassButton extends StatelessWidget {
  final bool compact;
  final String label;

  const CompassButton({
    super.key,
    this.compact = false,
    this.label = 'Compass',
  });

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CompassScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Compass (works offline)',
        icon: Icon(Icons.explore_outlined, color: AppColors.ink),
        onPressed: () => _open(context),
      );
    }

    // A visible outline matters here: card and paper are close in both
    // themes, so without the border the pill disappears into the page.
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.explore_rounded, size: 22, color: AppColors.pine),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'works offline',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.pine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}