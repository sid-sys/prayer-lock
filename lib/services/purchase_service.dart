import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';

/// Store billing (App Store and Google Play) with the `in_app_purchase` package.
///
/// Product IDs (same on both stores):
///   prayerlock_monthly   subscription, 7 day free trial
///   prayerlock_yearly    subscription, 7 day free trial
///   prayerlock_lifetime  one-time purchase
///
/// In a MOCK build, [buy] pretends the purchase worked so the app can be tested.
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

  static const _ids = {
    'monthly': 'prayerlock_monthly',
    'yearly': 'prayerlock_yearly',
    'lifetime': 'prayerlock_lifetime',
  };

  static String? _planOf(String productId) {
    for (final e in _ids.entries) {
      if (e.value == productId) return e.key;
    }
    return null;
  }

  static final _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static Completer<String?>? _waiting;
  static String? _wantedPlan;

  /// Call once at app start so purchases that finish later are not lost.
  static void listen() {
    if (kMockBuild || _sub != null) return;
    _sub = _iap.purchaseStream.listen(_onUpdates, onError: (_) {});
  }

  static Future<void> _onUpdates(List<PurchaseDetails> list) async {
    for (final p in list) {
      final plan = _planOf(p.productID);
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        if (plan != null) _finish(plan);
      } else if (p.status == PurchaseStatus.error || p.status == PurchaseStatus.canceled) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        _finish(null);
      }
    }
  }

  static void _finish(String? plan) {
    final w = _waiting;
    if (w != null && !w.isCompleted) w.complete(plan);
  }

  /// Buy a plan. Returns true when the store confirmed it.
  static Future<bool> buy(String plan) async {
    if (kMockBuild) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return true;
    }
    final id = _ids[plan];
    if (id == null || !await _iap.isAvailable()) return false;
    final res = await _iap.queryProductDetails({id});
    if (res.productDetails.isEmpty) return false;
    listen();
    _waiting = Completer<String?>();
    _wantedPlan = plan;
    final param = PurchaseParam(productDetails: res.productDetails.first);
    // Subscriptions and one-time products both start with this call.
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) return false;
    final got = await _waiting!.future.timeout(const Duration(minutes: 5), onTimeout: () => null);
    return got == _wantedPlan;
  }

  /// Ask the store for earlier purchases. Returns the plan found, or null.
  static Future<String?> restore() async {
    if (kMockBuild) return null;
    if (!await _iap.isAvailable()) return null;
    listen();
    _waiting = Completer<String?>();
    _wantedPlan = null;
    await _iap.restorePurchases();
    return _waiting!.future.timeout(const Duration(seconds: 8), onTimeout: () => null);
  }
}
