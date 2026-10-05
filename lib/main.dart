import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
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
    // Listening here means a theme change repaints every screen at once,
    // with no restart.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.modeNotifier,
      builder: (context, mode, _) {
        // Resolve before building, so AppColors returns the right set.
        AppTheme.resolve(context);
        return MaterialApp(
          title: 'TrailGuard Mindanao',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}

