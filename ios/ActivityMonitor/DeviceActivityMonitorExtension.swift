import DeviceActivity
import ManagedSettings

/// Runs in the background. When the open time after a prayer is over,
/// it puts the "Pray first" lock back on the chosen apps.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == DeviceActivityName(kRelockActivity) else { return }
        if ScreenTimeShared.defaults.bool(forKey: kEnabledKey) {
            ScreenTimeShared.applyShield()
        }
    }
}
