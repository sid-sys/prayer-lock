package com.coreinteractive.prayer_lock

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "prayer_lock/blocker")
            .setMethodCallHandler { call, result ->
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
                    else -> result.notImplemented()
                }
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
