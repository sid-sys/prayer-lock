import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The screen people see instead of a locked app.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private func shield() -> ShieldConfiguration {
        let ink = UIColor(red: 0.08, green: 0.08, blue: 0.11, alpha: 1)
        let peach = UIColor(red: 1.0, green: 0.79, blue: 0.60, alpha: 1)
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialLight,
            backgroundColor: peach,
            icon: UIImage(systemName: "hands.sparkles.fill"),
            title: ShieldConfiguration.Label(text: "Pray first \u{1F64F}", color: ink),
            subtitle: ShieldConfiguration.Label(
                text: "Take a moment with Jesus before you open this app.",
                color: ink.withAlphaComponent(0.75)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Pray now", color: .white),
            primaryButtonBackgroundColor: ink,
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration { shield() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { shield() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { shield() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { shield() }
}
