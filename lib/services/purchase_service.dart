/// Store billing wrapper.
///
/// NOT CONNECTED YET. To charge real money you need:
///  1. Google Play Console + App Store Connect products:
///     - Yearly subscription with a 7 day free trial
///     - Monthly subscription
///     - Lifetime (one-time purchase: "non-consumable" on Apple, "one-time product" on Google)
///  2. A billing package such as RevenueCat (`purchases_flutter`).
/// Until then [buy] pretends the purchase worked so the app can be tested.
class PurchaseService {
  /// Placeholder prices in US dollars. Replace with the real store prices
  /// (localized) later. Everything on screen, including "save %", follows these.
  static const monthlyUsd = 7.99;
  static const yearlyUsd = 39.99;
  static const lifetimeUsd = 79.99;

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';

  static String get monthlyPrice => _money(monthlyUsd);
  static String get yearlyPrice => _money(yearlyUsd);
  static String get lifetimePrice => _money(lifetimeUsd);
  static String get yearlyPerMonth => _money(yearlyUsd / 12);

  /// How much cheaper yearly is than paying monthly, as a whole percent.
  static int get savePercent => ((1 - (yearlyUsd / 12) / monthlyUsd) * 100).round();

  static String nameOf(String plan) => switch (plan) {
        'yearly' => 'Yearly',
        'monthly' => 'Monthly',
        'lifetime' => 'Lifetime',
        _ => 'Free',
      };

  static Future<bool> buy(String plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return true;
  }

  static Future<bool> restore() async => false;
}
