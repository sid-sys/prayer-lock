import Flutter
import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Bridge between the Flutter app and Apple's Screen Time tools.
/// Same channel name as the Android version, so the Dart code stays the same.
final class ScreenTimePlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "prayer_lock/blocker",
                                           binaryMessenger: registrar.messenger())
        let instance = ScreenTimePlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        // When the user comes back from the shield ("Pray now"), tell Flutter.
        NotificationCenter.default.addObserver(
            self, selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appBecameActive() {
        if ScreenTimeShared.defaults.bool(forKey: kPendingKey) {
            ScreenTimeShared.defaults.set(false, forKey: kPendingKey)
            channel.invokeMethod("blocked", arguments: "ios")
        }
    }

    // MARK: - Flutter calls

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "hasPermission":
            result(AuthorizationCenter.shared.authorizationStatus == .approved)

        case "requestPermission":
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                } catch {
                    // The user said no, or something went wrong. We just report the state.
                }
                result(AuthorizationCenter.shared.authorizationStatus == .approved)
            }

        case "pickApps":
            presentPicker(result: result)

        case "summary":
            result(summary())

        case "clearChoice":
            ScreenTimeShared.saveSelection(FamilyActivitySelection())
            ScreenTimeShared.clearShield()
            result(nil)

        case "update":
            let args = call.arguments as? [String: Any] ?? [:]
            let enabled = (args["enabled"] as? Bool) ?? true
            let until = (args["unlockedUntil"] as? NSNumber)?.int64Value ?? 0
            update(enabled: enabled, unlockedUntilMs: until)
            result(nil)

        case "consumeBlocked":
            if ScreenTimeShared.defaults.bool(forKey: kPendingKey) {
                ScreenTimeShared.defaults.set(false, forKey: kPendingKey)
                result("ios")
            } else {
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Locking

    private func update(enabled: Bool, unlockedUntilMs: Int64) {
        let d = ScreenTimeShared.defaults
        d.set(enabled, forKey: kEnabledKey)
        d.set(unlockedUntilMs, forKey: kUntilKey)

        let center = DeviceActivityCenter()
        let relock = DeviceActivityName(kRelockActivity)
        center.stopMonitoring([relock])

        guard AuthorizationCenter.shared.authorizationStatus == .approved else { return }

        guard enabled else {
            ScreenTimeShared.clearShield()
            return
        }

        let now = Date()
        let until = Date(timeIntervalSince1970: Double(unlockedUntilMs) / 1000)
        if until > now {
            // Prayer done: open the apps, and put the lock back when time is over.
            ScreenTimeShared.clearShield()
            scheduleRelock(at: until, center: center, name: relock)
        } else {
            ScreenTimeShared.applyShield()
        }
    }

    private func scheduleRelock(at end: Date, center: DeviceActivityCenter, name: DeviceActivityName) {
        let cal = Calendar.current
        let start = cal.dateComponents([.hour, .minute, .second], from: Date())
        let stop = cal.dateComponents([.hour, .minute, .second], from: end)
        let schedule = DeviceActivitySchedule(intervalStart: start, intervalEnd: stop, repeats: false)
        do {
            try center.startMonitoring(name, during: schedule)
        } catch {
            // Apple needs at least 15 minutes. If it fails, the app puts the lock
            // back the next time it is opened.
        }
    }

    // MARK: - App picker

    private func summary() -> [String: Int] {
        let s = ScreenTimeShared.loadSelection()
        return [
            "apps": s.applicationTokens.count,
            "categories": s.categoryTokens.count,
            "websites": s.webDomainTokens.count,
        ]
    }

    private func presentPicker(result: @escaping FlutterResult) {
        guard let top = Self.topViewController() else {
            result(summary())
            return
        }
        var finished = false
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        let view = PickerScreen(initial: ScreenTimeShared.loadSelection()) { picked in
            if let picked = picked {
                ScreenTimeShared.saveSelection(picked)
                // If apps are locked right now, cover the new choice at once.
                let until = ScreenTimeShared.defaults.object(forKey: kUntilKey) as? Int64 ?? 0
                let enabled = ScreenTimeShared.defaults.object(forKey: kEnabledKey) as? Bool ?? true
                if enabled && Date(timeIntervalSince1970: Double(until) / 1000) <= Date()
                    && AuthorizationCenter.shared.authorizationStatus == .approved {
                    ScreenTimeShared.applyShield()
                }
            }
            host.dismiss(animated: true) {
                if !finished {
                    finished = true
                    result(self.summary())
                }
            }
        }
        host.rootView = AnyView(view)
        host.modalPresentationStyle = .pageSheet
        top.present(host, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ??
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// Apple's own app picker, with a Done and a Cancel button.
private struct PickerScreen: View {
    @State var selection: FamilyActivitySelection
    let done: (FamilyActivitySelection?) -> Void

    init(initial: FamilyActivitySelection, done: @escaping (FamilyActivitySelection?) -> Void) {
        _selection = State(initialValue: initial)
        self.done = done
    }

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Choose apps to lock")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { done(nil) }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { done(selection) }
                    }
                }
        }
    }
}
