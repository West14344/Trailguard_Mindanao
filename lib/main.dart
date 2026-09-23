import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  // Firebase must be ready before any screen tries to use it.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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