package com.coreinteractive.prayer_lock

import android.content.ComponentName
import android.content.Context
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.os.Process
import android.provider.Settings
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
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
                // Usage access: time spent per app (the user turns it on in phone Settings).
                "hasUsageAccess" -> result.success(hasUsageAccess())
                "requestUsageAccess" -> {
                    startActivity(
                        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(null)
                }
                "usageByDay" -> {
                    val days = (call.argument<Number>("days") ?: 7).toInt().coerceIn(1, 30)
                    val pkgs = (call.argument<List<String>>("packages") ?: emptyList()).toSet()
                    result.success(usageByDay(days, pkgs))
                }
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

    private fun hasUsageAccess(): Boolean {
        return try {
            val ops = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            @Suppress("DEPRECATION")
            val mode = ops.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    /// For each of the last [days] days: minutes in the foreground for the chosen apps.
    /// Returns a list like [{"day": "2026-10-12", "minutes": {"com.app": 12}}].
    private fun usageByDay(days: Int, pkgs: Set<String>): List<Map<String, Any>> {
        if (!hasUsageAccess()) return emptyList()
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val out = ArrayList<Map<String, Any>>()
        for (back in 0 until days) {
            val start = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -back)
                set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            }
            val end = (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
            val stats = usm.queryAndAggregateUsageStats(start.timeInMillis, end.timeInMillis)
            val minutes = HashMap<String, Int>()
            for ((pkg, s) in stats) {
                if (pkgs.isNotEmpty() && !pkgs.contains(pkg)) continue
                val m = (s.totalTimeInForeground / 60000L).toInt()
                if (m > 0) minutes[pkg] = m
            }
            out.add(mapOf("day" to fmt.format(start.time), "minutes" to minutes))
        }
        return out
    }

    private fun isServiceOn(): Boolean {
        val id = ComponentName(this, BlockerAccessibilityService::class.java).flattenToString()
        val enabled = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(':').any { it.equals(id, ignoreCase = true) }
    }
}
