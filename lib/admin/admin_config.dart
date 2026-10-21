import '../config.dart';

/// Rules for "Real users only". Edit this file, not the screens.
///
/// An account is hidden from every number, chart, list and funnel when ANY
/// rule below matches it. The panel always shows the reason.
class AdminConfig {
  /// Your own account. Your taps must not count as customers.
  static const adminEmails = [kAdminEmail];

  /// The store review team's login (Play Console and App Store Connect).
  static const reviewEmails = ['playreview.login@gmail.com'];

  /// Test-robot email domains (Firebase Test Lab, Google's test robots).
  static const robotDomains = ['cloudtestlabaccounts.com'];

  /// Nobody can read and answer onboarding in less than this.
  static const minOnboardingSeconds = 25;

  /// Money: what the stores keep (small business programs), and our costs.
  static const storeCut = 0.15;
  static const aiCostPerPrayer = 0.0001;
  static const fixedCostPerMonth = 12.0;
}
