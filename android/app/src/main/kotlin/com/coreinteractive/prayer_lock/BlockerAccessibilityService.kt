package com.coreinteractive.prayer_lock

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import java.util.Calendar

/**
 * Watches which app comes to the front. If the app is on the locked list
 * and the user has not prayed (unlock time is over), open Prayer Lock.
 */
class BlockerAccessibilityService : AccessibilityService() {
    private var lastKick = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName) return

        val prefs = getSharedPreferences("blocker", Context.MODE_PRIVATE)
        val locked = prefs.getStringSet("packages", emptySet()) ?: emptySet()
        if (!locked.contains(pkg)) return

        val now = System.currentTimeMillis()
        if (now - lastKick < 1500) return

        if (prefs.getLong("until", 0L) > now) {
            // The app is open (the person prayed). Nudge only if a morning or
            // night prayer is waiting, at most once every 45 minutes.
            val due = duePrayer(prefs) ?: return
            if (now - prefs.getLong("lastNudge", 0L) < 45 * 60 * 1000L) return
            prefs.edit().putLong("lastNudge", now).apply()
            lastKick = now
            startActivity(Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                putExtra("blocked_package", pkg)
                putExtra("reminder_kind", due)
            })
            return
        }

        lastKick = now
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("blocked_package", pkg)
        }
        startActivity(intent)
    }

    /** "morning" or "night" if that prayer is waiting right now, else null. */
    private fun duePrayer(prefs: android.content.SharedPreferences): String? {
        val morning = prefs.getInt("morningMin", -1)
        val night = prefs.getInt("nightMin", -1)
        if (morning < 0 || night < 0) return null
        val c = Calendar.getInstance()
        val mins = c.get(Calendar.HOUR_OF_DAY) * 60 + c.get(Calendar.MINUTE)
        val today = String.format(
            "%04d-%02d-%02d", c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH)
        )
        if (mins >= night && prefs.getString("nightDone", "") != today) return "night"
        if (mins >= morning && mins < night && prefs.getString("morningDone", "") != today) return "morning"
        return null
    }

    override fun onInterrupt() {}
}
