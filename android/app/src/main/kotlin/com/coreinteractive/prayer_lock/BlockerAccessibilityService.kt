package com.coreinteractive.prayer_lock

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

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
        if (prefs.getLong("until", 0L) > System.currentTimeMillis()) return

        val now = System.currentTimeMillis()
        if (now - lastKick < 1500) return
        lastKick = now

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("blocked_package", pkg)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {}
}
