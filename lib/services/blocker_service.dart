import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import '../config.dart';

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

  static List<AppInfo> _sampleApps() {
    const names = {
      'com.instagram.android': 'Instagram',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.google.android.youtube': 'YouTube',
      'com.whatsapp.w4b': 'WhatsApp Business',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'X',
      'com.snapchat.android': 'Snapchat',
      'com.netflix.mediaclient': 'Netflix',
      'com.reddit.frontpage': 'Reddit',
      'com.pinterest': 'Pinterest',
      'com.spotify.music': 'Spotify',
      'com.amazon.mShop': 'Amazon Shopping',
    };
    return [
      for (final e in names.entries)
        AppInfo(
          name: e.value,
          icon: null,
          packageName: e.key,
          versionName: '1.0',
          versionCode: 1,
          platformType: PlatformType.nativeOrOthers,
          installedTimestamp: 0,
          isSystemApp: false,
          isLaunchableApp: true,
          category: AppCategory.undefined,
        ),
    ];
  }

  static Future<List<AppInfo>> _load() async {
    if (kShotMode) return _sampleApps(); // screenshots on a simulator
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
    bool enabled = true,
  }) async {
    try {
      await _ch.invokeMethod('update', {
        'packages': packages,
        'unlockedUntil': unlockedUntil?.millisecondsSinceEpoch ?? 0,
        'enabled': enabled,
      });
    } on MissingPluginException {
      // native side not ready yet
    } catch (_) {}
  }

  /// Called when a locked app was opened and Prayer Lock came to the front.
  static void listenBlocked(void Function(String pkg) onBlocked) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'blocked' && call.arguments is String) {
        onBlocked(call.arguments as String);
      }
    });
    // App was started by a locked app (not running before)?
    _ch.invokeMethod<String>('consumeBlocked').then((pkg) {
      if (pkg != null) onBlocked(pkg);
    }).catchError((_) {});
  }

  /// Open an app by package name (after the user prayed).
  static Future<void> launchApp(String pkg) async {
    try {
      await _ch.invokeMethod('launchApp', {'package': pkg});
    } catch (_) {}
  }

  /// iPhone only: open Apple's app picker. Returns how many apps, categories
  /// and websites are chosen now.
  static Future<Map<String, int>> pickApps() async {
    try {
      final r = await _ch.invokeMethod<Map>('pickApps');
      return _counts(r);
    } catch (_) {
      return {'apps': 0, 'categories': 0, 'websites': 0};
    }
  }

  /// iPhone only: forget the chosen apps and open them all.
  static Future<void> clearChoice() async {
    try {
      await _ch.invokeMethod('clearChoice');
    } catch (_) {}
  }

  /// iPhone only: how many apps, categories and websites are chosen.
  static Future<Map<String, int>> summary() async {
    try {
      return _counts(await _ch.invokeMethod<Map>('summary'));
    } catch (_) {
      return {'apps': 0, 'categories': 0, 'websites': 0};
    }
  }

  static Map<String, int> _counts(Map? m) => {
        'apps': (m?['apps'] as num?)?.toInt() ?? 0,
        'categories': (m?['categories'] as num?)?.toInt() ?? 0,
        'websites': (m?['websites'] as num?)?.toInt() ?? 0,
      };

  // ---- Android: time spent per app ("usage access") ----

  static Future<bool> hasUsageAccess() async {
    try {
      return await _ch.invokeMethod<bool>('hasUsageAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestUsageAccess() async {
    try {
      await _ch.invokeMethod('requestUsageAccess');
    } catch (_) {}
  }

  /// Minutes per app for each of the last [days] days (only for [packages]).
  /// Returns {"2026-10-12": {"com.app": 12}}.
  static Future<Map<String, Map<String, int>>> usageByDay(
      int days, List<String> packages) async {
    try {
      final r = await _ch.invokeMethod<List>('usageByDay', {'days': days, 'packages': packages});
      final out = <String, Map<String, int>>{};
      for (final item in r ?? const []) {
        final m = item as Map;
        final minutes = <String, int>{};
        (m['minutes'] as Map? ?? {}).forEach((k, v) => minutes[k as String] = (v as num).toInt());
        out[m['day'] as String] = minutes;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Name of an app from its package (uses the loaded app list).
  static String nameOf(String pkg) {
    for (final a in loaded ?? const <AppInfo>[]) {
      if (a.packageName == pkg) return a.name;
    }
    final last = pkg.split('.').last;
    return last.isEmpty ? pkg : last[0].toUpperCase() + last.substring(1);
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
