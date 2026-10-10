/// Store billing wrapper.
///
/// NOT CONNECTED YET. To charge real money you need:
///  1. Google Play Console + App Store Connect subscriptions
///     (yearly with 7 day free trial, and monthly).
///  2. A billing package such as RevenueCat (`purchases_flutter`).
/// Until then [buy] pretends the purchase worked so the app can be tested.
class PurchaseService {
  /// Shown prices. Replace with real store prices (localized) later.
  static const yearlyPrice = r'$29.99';
  static const yearlyPerMonth = r'$2.50';
  static const monthlyPrice = r'$9.99';

  static Future<bool> buy(String plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return true;
  }

  static Future<bool> restore() async => false;
}
