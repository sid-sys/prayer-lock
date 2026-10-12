import ManagedSettings
import UserNotifications

/// What happens when the person taps "Pray now" on the lock screen.
/// An extension cannot open our app directly, so we send a notification.
/// Tapping it opens Prayer Lock, which then shows the prayer.
class ShieldActionExtension: ShieldActionDelegate {
    private func respond(_ action: ShieldAction, _ done: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            ScreenTimeShared.defaults.set(true, forKey: kPendingKey)
            notify()
            done(.close)
        default:
            done(.close)
        }
    }

    private func notify() {
        let content = UNMutableNotificationContent()
        content.title = "\u{1F64F} Time to pray"
        content.body = "Tap here to open Prayer Lock, pray, then continue."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "pray-now", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(action, completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(action, completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(action, completionHandler)
    }
}
