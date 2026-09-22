import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'group_screen.dart';
import 'profile_screen.dart';
import 'trail_map_screen.dart';

/// Holds the five tabs. IndexedStack keeps each tab's scroll position
/// when you switch away and back.
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  /// Bumped whenever a tab is selected. Passing it as a key forces the
  /// tab to rebuild, so stats recorded on another tab show up immediately.
  int _visitCount = 0;

  void _select(int i) => setState(() {
        _index = i;
        _visitCount++;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(key: ValueKey('dashboard-$_visitCount')),
          const TrailMapScreen(),
          const AlertsScreen(),
          const GroupScreen(),
          ProfileScreen(key: ValueKey('profile-$_visitCount')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: _select,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.card,
            elevation: 0,
            selectedItemColor: AppColors.forest,
            unselectedItemColor: AppColors.inkSoft,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.warning_amber_outlined),
                activeIcon: Icon(Icons.warning_amber_rounded),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: 'Group',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}