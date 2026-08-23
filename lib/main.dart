import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const TrailGuardApp());
}

class TrailGuardApp extends StatelessWidget {
  const TrailGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrailGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const WelcomeScreen(),
    );
  }
}