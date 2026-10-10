import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

/// Talks to native code that blocks apps.
/// Android: native side (Accessibility service) comes in the next step.
/// iOS: needs Apple Screen Time approval. Until then calls do nothing.
class BlockerService {
  static const _ch = MethodChannel('prayer_lock/blocker');

  static Future<List<AppInfo>> installedApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
        detectPlatformType: false,
      );
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return apps.where((a) => a.packageName != 'com.coreinteractive.prayer_lock').toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> update({
    required List<String> packages,
    required DateTime? unlockedUntil,
  }) async {
    try {
      await _ch.invokeMethod('update', {
        'packages': packages,
        'unlockedUntil': unlockedUntil?.millisecondsSinceEpoch ?? 0,
      });
    } on MissingPluginException {
      // native side not ready yet
    } catch (_) {}
  }

  static Future<bool> hasPermission() async {
    try {
      return await _ch.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _ch.invokeMethod('requestPermission');
    } catch (_) {}
  }
}
