import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/app_background.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'locked_apps_screen.dart';
import 'settings_screen.dart';

class Shell extends StatefulWidget {
  /// Start on this tab (used by screenshot mode).
  final int initialIndex;
  const Shell({super.key, this.initialIndex = 0});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _i = widget.initialIndex;

  static const _pages = <Widget>[
    HomeScreen(),
    InsightsScreen(),
    LockedAppsScreen(),
    SettingsScreen(),
  ];

  // (idle icon, selected icon, label)
  static const _items = [
    ('ic_home', 'ic_home_on', 'Home'),
    ('ic_insights', 'ic_insights_on', 'Insights'),
    ('ic_apps', 'ic_apps_on', 'Locked apps'),
    ('ic_profile', 'ic_profile_on', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      body: AppBackground(
        child: SafeArea(
          child: IndexedStack(index: _i, children: _pages),
        ),
      ),
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
                        opacity: _i == k ? 1 : 0.75,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: _i == k ? 1.15 : 0.95,
                              child: Pic(
                                _i == k ? _items[k].$2 : _items[k].$1,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _items[k].$3,
                              style: h(
                                12,
                                w: _i == k ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
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
