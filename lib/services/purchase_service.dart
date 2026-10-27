import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../config.dart';

/// Store billing (App Store and Google Play) with the `in_app_purchase` package.
///
/// Product IDs (same on both stores):
///   prayerlock_pro_monthly   subscription, 7 day free trial
///   prayerlock_pro_yearly    subscription, 7 day free trial
///   prayerlock_pro_lifetime  one-time purchase
///
/// In a MOCK build, [buy] pretends the purchase worked so the app can be tested.
class PurchaseService {
  /// Placeholder prices in US dollars. Replace with the real store prices
  /// (localized) later. Everything on screen, including "save %", follows these.
  static const monthlyUsd = 4.99;
  static const yearlyUsd = 29.99;
  static const lifetimeUsd = 49.99;

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';

  static String get monthlyPrice => _money(monthlyUsd);
  static String get yearlyPrice => _money(yearlyUsd);
  static String get lifetimePrice => _money(lifetimeUsd);
  static String get yearlyPerMonth => _money(yearlyUsd / 12);

  /// How much cheaper yearly is than paying monthly, as a whole percent.
  static int get savePercent => ((1 - (yearlyUsd / 12) / monthlyUsd) * 100).round();

  /// The 4 benefits shown on every plan (also entered in the stores).
  static const proBenefits = [
    ('🔒', 'Lock distracting apps until you pray'),
    ('🙏', 'AI prayers for your mood + daily verse'),
    ('🔔', 'Morning and night prayer reminders'),
    ('📊', 'Streaks, badges and prayer insights'),
  ];

  /// Plan title, the same as in the stores.
  static String proName(String plan) => 'Prayer Lock Pro ${nameOf(plan)}';

  /// One line under the plan name, the same as in the stores.
  static String descriptionOf(String plan) => switch (plan) {
        'monthly' => 'Pray before you scroll. 7 days free, then billed monthly. Cancel any time.',
        'yearly' => 'Best value. 7 days free, then billed yearly. Save $savePercent%. Cancel any time.',
        _ => 'Pay once, keep Prayer Lock for life. No renewals, no free trial.',
      };

  static String nameOf(String plan) => switch (plan) {
        'yearly' => 'Yearly',
        'monthly' => 'Monthly',
        'lifetime' => 'Lifetime',
        _ => 'Free',
      };

  static const _ids = {
    'monthly': 'prayerlock_pro_monthly',
    'yearly': 'prayerlock_pro_yearly',
    'lifetime': 'prayerlock_pro_lifetime',
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

  /// On Android a subscription with a free-trial offer comes back as several
  /// entries (the plain base plan and the trial offer). Take the free-trial
  /// one, so new customers get their 7 free days. Otherwise take the first.
  static ProductDetails _pick(List<ProductDetails> list) {
    for (final d in list) {
      if (d is GooglePlayProductDetails) {
        final offers = d.productDetails.subscriptionOfferDetails;
        final i = d.subscriptionIndex;
        if (offers != null && i != null && i < offers.length) {
          final phases = offers[i].pricingPhases;
          if (phases.isNotEmpty && phases.first.priceAmountMicros == 0) return d;
        }
      }
    }
    return list.first;
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
    final param = PurchaseParam(productDetails: _pick(res.productDetails));
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
