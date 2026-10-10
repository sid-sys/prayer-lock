import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

/// Talks to native code that blocks apps.
/// Android: Accessibility service (see BlockerAccessibilityService.kt).
/// iOS: needs Apple Screen Time approval. Until then calls do nothing.
class BlockerService {
  static const _ch = MethodChannel('prayer_lock/blocker');

  static Future<List<AppInfo>>? _loading;

  /// Already loaded list, or null while loading. Lets the screen open instantly.
  static List<AppInfo>? loaded;

  /// Start loading the app list early (called when the app starts).
  static void preload() {
    installedApps();
  }

  static Future<List<AppInfo>> installedApps() =>
      _loading ??= _load().then((a) => loaded = a);

  static Future<List<AppInfo>> _load() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
        detectPlatformType: false,
      );
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return apps.where((a) => a.packageName != 'com.coreinteractive.prayer_lock').toList();
    } catch (_) {
      _loading = null; // try again next time
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
