import "package:flutter/material.dart";
import "../theme/app_theme.dart";

/// Shown while the profile and hike history load after signing in.
/// Drawn with CustomPaint so it needs no asset or package.
class HikingLoader extends StatefulWidget {
  final String message;
  const HikingLoader({super.key, this.message = "Getting your trails ready"});

  @override
  State<HikingLoader> createState() => _HikingLoaderState();
}

class _HikingLoaderState extends State<HikingLoader>
    with TickerProviderStateMixin {
  /// Drives the walk cycle: legs, arms and the bob of the body.
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..repeat();

  /// Moves the hiker along the slope, then resets.
  late final AnimationController _journey = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _walk.dispose();
    _journey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: Listenable.merge([_walk, _journey]),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(260, 190),
                  painter: _TrailPainter(
                    walk: _walk.value,
                    progress: _journey.value,
                  ),
                );
              },
            ),
            const SizedBox(height: 34),
            Text(
              widget.message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const _Dots(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Text(
                "TrailGuard Mindanao",
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots that fill in turn, so the wait reads as progress.
class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final active = (_c.value * 3).floor() % 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final on = i == active;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: on ? 9 : 6,
              height: on ? 9 : 6,
              decoration: BoxDecoration(
                color: on ? AppColors.forest : AppColors.line,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Paints the ridgeline, a sun, and the hiker climbing it.
class _TrailPainter extends CustomPainter {
  final double walk;
  final double progress;

  _TrailPainter({required this.walk, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- sun -------------------------------------------------------------
    canvas.drawCircle(
      Offset(w * 0.80, h * 0.16),
      15,
      Paint()..color = AppColors.mist,
    );
    canvas.drawCircle(
      Offset(w * 0.80, h * 0.16),
      9,
      Paint()..color = AppColors.blaze.withAlpha(150),
    );

    // --- far ridge -------------------------------------------------------
    final farRidge = Path()
      ..moveTo(0, h * 0.72)
      ..lineTo(w * 0.22, h * 0.40)
      ..lineTo(w * 0.40, h * 0.60)
      ..lineTo(w * 0.60, h * 0.30)
      ..lineTo(w * 0.82, h * 0.58)
      ..lineTo(w, h * 0.44)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(farRidge, Paint()..color = AppColors.mist);

    // --- the slope the hiker walks on ------------------------------------
    // A straight climb from bottom-left to upper-right.
    final startX = w * 0.06;
    final startY = h * 0.92;
    final endX = w * 0.90;
    final endY = h * 0.50;

    final trail = Paint()
      ..color = AppColors.forest
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), trail);

    // Ground below the trail.
    final ground = Path()
      ..moveTo(startX, startY)
      ..lineTo(endX, endY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = AppColors.forest.withAlpha(38));

    // --- flag at the summit ----------------------------------------------
    final poleTop = Offset(endX, endY - 26);
    canvas.drawLine(
      Offset(endX, endY),
      poleTop,
      Paint()
        ..color = AppColors.pine
        ..strokeWidth = 2.5,
    );
    final flag = Path()
      ..moveTo(poleTop.dx, poleTop.dy)
      ..lineTo(poleTop.dx + 17, poleTop.dy + 6)
      ..lineTo(poleTop.dx, poleTop.dy + 12)
      ..close();
    canvas.drawPath(flag, Paint()..color = AppColors.alert);

    // --- the hiker --------------------------------------------------------
    final t = progress;
    final x = startX + (endX - startX) * t;
    // A small bob so the walk does not look like a slide.
    final bob = (walk < 0.5 ? walk : 1 - walk) * 3;
    final y = startY + (endY - startY) * t - bob;

    _paintHiker(canvas, Offset(x, y), walk);
  }

  void _paintHiker(Canvas canvas, Offset feet, double phase) {
    final body = Paint()
      ..color = AppColors.pine
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final hip = feet.translate(0, -20);
    final shoulder = feet.translate(0, -34);

    // Legs swing in opposition, sine wave keeps it smooth.
    final swing = (phase * 2 * 3.14159);
    final legSwing = 7.0;
    final frontFoot = Offset(
      feet.dx + legSwing * _sin(swing),
      feet.dy,
    );
    final backFoot = Offset(
      feet.dx - legSwing * _sin(swing),
      feet.dy,
    );

    canvas.drawLine(hip, frontFoot, body);
    canvas.drawLine(hip, backFoot, body);
    canvas.drawLine(hip, shoulder, body);

    // Head.
    canvas.drawCircle(
      shoulder.translate(0, -7),
      6,
      Paint()..color = AppColors.pine,
    );

    // Backpack, sitting behind the shoulders.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(shoulder.dx - 11, shoulder.dy - 3, 8, 13),
        const Radius.circular(2.5),
      ),
      Paint()..color = AppColors.blaze,
    );

    // Arms, opposite to the legs.
    final armSwing = 6.0;
    canvas.drawLine(
      shoulder,
      shoulder.translate(armSwing * -_sin(swing), 11),
      body..strokeWidth = 2.8,
    );

    // Trekking pole, planted with the forward arm.
    final poleHand = shoulder.translate(armSwing * _sin(swing) + 3, 11);
    final poleTip = Offset(poleHand.dx + 9, feet.dy + 2);
    canvas.drawLine(
      poleHand,
      poleTip,
      Paint()
        ..color = AppColors.inkSoft
        ..strokeWidth = 2,
    );
  }

  double _sin(double radians) {
    // Small local sine so the file needs no dart:math import.
    var x = radians % 6.28318;
    if (x > 3.14159) x -= 6.28318;
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120);
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.walk != walk || old.progress != progress;
}











