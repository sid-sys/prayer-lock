import Foundation
import FamilyControls
import ManagedSettings

// This file is compiled into the app AND all three extensions.
// It holds the things they must agree on.

/// Shared storage (App Group). The app and the extensions all read and write here.
let kAppGroup = "group.com.coreinteractive.prayerLock"

let kSelectionKey = "selection"      // which apps the user chose (encoded)
let kEnabledKey = "enabled"          // blocking switched on in Profile
let kUntilKey = "unlockedUntil"      // time (ms) until which apps stay open after praying
let kPendingKey = "pendingPrayer"    // user tapped "Pray now" on the shield

/// Name of the schedule that puts the lock back when the open time ends.
let kRelockActivity = "relock"

enum ScreenTimeShared {
    static var defaults: UserDefaults {
        UserDefaults(suiteName: kAppGroup) ?? UserDefaults.standard
    }

    /// Our own settings store, so we never touch other apps' settings.
    static var store: ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name("prayerlock"))
    }

    static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: kSelectionKey),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? PropertyListEncoder().encode(selection) {
            defaults.set(data, forKey: kSelectionKey)
        }
    }

    /// Cover the chosen apps with the "Pray first" shield.
    static func applyShield() {
        let selection = loadSelection()
        let s = store
        s.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        s.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        s.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    /// Take the shield off (apps are open).
    static func clearShield() {
        store.clearAllSettings()
    }
}
