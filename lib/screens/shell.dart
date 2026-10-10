import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'locked_apps_screen.dart';
import 'settings_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    InsightsScreen(),
    LockedAppsScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    ('nav_home', 'Home'),
    ('nav_insights', 'Insights'),
    ('nav_locked', 'Locked apps'),
    ('nav_profile', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _i, children: _pages)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Row(
              children: [
                for (var k = 0; k < _items.length; k++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _i = k),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _i == k ? 1 : 0.45,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: _i == k ? 1.15 : 0.95,
                              child: Pic(_items[k].$1, size: 38),
                            ),
                            const SizedBox(height: 2),
                            Text(_items[k].$2,
                                style: h(12, w: _i == k ? FontWeight.w800 : FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
