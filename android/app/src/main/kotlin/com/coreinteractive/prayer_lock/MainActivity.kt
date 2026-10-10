package com.coreinteractive.prayer_lock

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /// Package of a locked app the user just tried to open (not handled yet).
    private var pendingBlocked: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        readBlocked(intent)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "prayer_lock/blocker")
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val pkgs = call.argument<List<String>>("packages") ?: emptyList()
                    val until = (call.argument<Number>("unlockedUntil") ?: 0).toLong()
                    getSharedPreferences("blocker", Context.MODE_PRIVATE).edit()
                        .putStringSet("packages", pkgs.toSet())
                        .putLong("until", until)
                        .apply()
                    result.success(null)
                }
                "hasPermission" -> result.success(isServiceOn())
                "requestPermission" -> {
                    startActivity(
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(null)
                }
                // Dart asks once at start: was I opened because of a locked app?
                "consumeBlocked" -> {
                    result.success(pendingBlocked)
                    pendingBlocked = null
                }
                // After praying, open the app the user wanted.
                "launchApp" -> {
                    val pkg = call.argument<String>("package")
                    val launch = pkg?.let { packageManager.getLaunchIntentForPackage(it) }
                    if (launch != null) {
                        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launch)
                    }
                    result.success(launch != null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readBlocked(intent)
        // App is already running: tell Dart right away.
        pendingBlocked?.let { pkg ->
            channel?.invokeMethod("blocked", pkg)
            pendingBlocked = null
        }
    }

    private fun readBlocked(i: Intent?) {
        val pkg = i?.getStringExtra("blocked_package")
        if (pkg != null) {
            pendingBlocked = pkg
            i.removeExtra("blocked_package")
        }
    }

    private fun isServiceOn(): Boolean {
        val id = ComponentName(this, BlockerAccessibilityService::class.java).flattenToString()
        val enabled = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(':').any { it.equals(id, ignoreCase = true) }
    }
}
