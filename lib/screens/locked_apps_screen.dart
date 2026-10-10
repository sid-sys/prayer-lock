import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import '../services/blocker_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class LockedAppsScreen extends StatefulWidget {
  const LockedAppsScreen({super.key});
  @override
  State<LockedAppsScreen> createState() => _LockedAppsScreenState();
}

class _LockedAppsScreenState extends State<LockedAppsScreen> {
  List<AppInfo>? _apps;
  String _q = '';

  @override
  void initState() {
    super.initState();
    BlockerService.installedApps().then((a) {
      if (mounted) setState(() => _apps = a);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final apps = _apps;
    final shown = apps
        ?.where((a) => a.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(child: Text('Locked apps', style: serif(26))),
              Text('${s.lockedApps.length} locked',
                  style: const TextStyle(color: AppColors.gold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search apps',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              TextButton(
                onPressed: apps == null
                    ? null
                    : () => s.setAll(apps.map((a) => a.packageName).toList()),
                child: const Text('Block everything'),
              ),
              TextButton(
                onPressed: () => s.setAll([]),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: shown == null
              ? const Center(child: CircularProgressIndicator())
              : shown.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No apps found. App list works on Android phones.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.soft),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final a = shown[i];
                        final on = s.lockedApps.contains(a.packageName);
                        return SwitchListTile(
                          value: on,
                          onChanged: (_) => s.toggleApp(a.packageName),
                          secondary: a.icon == null
                              ? const Icon(Icons.apps)
                              : Image.memory(a.icon!, width: 40, height: 40),
                          title: Text(a.name),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
