import "dart:async";

import "package:flutter/material.dart";
import "../theme/app_theme.dart";
import "welcome_screen.dart";

/// Shown briefly after the native splash: the logo, and three dots that
/// bounce while the app settles.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, _, _) => const WelcomeScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset(
                "assets/images/logo.png",
                height: 130,
                semanticLabel: "TrailGuard Mindanao",
              ),
            ),
            const SizedBox(height: 40),
            const _BouncingDots(),
          ],
        ),
      ),
    );
  }
}

/// Three dots that rise and fall in sequence.
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Each dot starts a third of a cycle after the one before it.
            final phase = (_c.value - (i * 0.18)) % 1.0;
            // Only the first part of the cycle lifts the dot; the rest is
            // a pause, so the group reads as a wave rather than a jitter.
            final lift = phase < 0.4
                ? Curves.easeOut.transform(
                    (phase < 0.2 ? phase : 0.4 - phase) / 0.2)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -9 * lift),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withAlpha(
                        (140 + (115 * lift)).round()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
