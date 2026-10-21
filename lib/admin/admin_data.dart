import 'dart:math';

import '../services/purchase_service.dart';
import 'admin_config.dart';

/// Everything the admin panel shows is built from a list of [AdminUser].
/// Today the list is made up ([MockAdminRepository]) because there are no
/// real users yet. Later a real repository can read the same shape from the
/// server, and the screens stay the same.

class AdminEvent {
  final DateTime at;
  final String type;
  final String detail;
  const AdminEvent(this.at, this.type, this.detail);

  String get emoji => switch (type) {
    'opened' => '👋',
    'onboarding_done' => '✅',
    'committed' => '🙏',
    'signed_up' => '🆔',
    'paywall_view' => '💳',
    'payment_attempt' => '🧾',
    'payment_failed' => '⚠️',
    'subscribed' => '👑',
    'prayer_morning' => '🌅',
    'prayer_night' => '🌙',
    'prayer_gate' => '🔒',
    'apps_locked' => '📵',
    'uninstalled' => '🗑️',
    _ => '•',
  };

  String get title => switch (type) {
    'opened' => 'Opened the app',
    'onboarding_done' => 'Finished onboarding',
    'committed' => 'Committed devotion to Jesus',
    'signed_up' => 'Created an account',
    'paywall_view' => 'Saw the paywall',
    'payment_attempt' => 'Tried to pay',
    'payment_failed' => 'Payment did not happen',
    'subscribed' => 'Subscribed',
    'prayer_morning' => 'Morning prayer',
    'prayer_night' => 'Night prayer',
    'prayer_gate' => 'Prayer before opening an app',
    'apps_locked' => 'Locked apps',
    'uninstalled' => 'Removed the app',
    _ => type,
  };
}

class AdminPayment {
  final DateTime at;
  final double amount;
  const AdminPayment(this.at, this.amount);
}

/// Why a payment did not happen. Keys are stored with the user.
class PayFail {
  final DateTime at;
  final String kind; // 'cancelled', 'failed', 'store'
  const PayFail(this.at, this.kind);
}

const payFailTitles = {
  'cancelled': 'Cancelled',
  'failed': 'Failed',
  'store': 'Store not available',
};
const payFailReasons = {
  'cancelled': 'The person closed the store sheet before paying.',
  'failed':
      'The store tried but the payment was refused (card, balance or bank).',
  'store': 'The phone could not reach Google Play or the App Store (no store app, not signed in, or no internet).',
};

class AdminUser {
  final String id;
  final String? name; // real name they gave, or null
  final String? email; // real email, or null (guest)
  final String country;
  final bool isGuest;
  final DateTime installedAt;
  final DateTime joinedAt;
  final DateTime lastSeen;
  final DateTime? uninstalledAt;
  final String? heardFrom;
  final int? onboardingSeconds;
  final bool onboardingDone;
  final bool committed;
  final bool prayedOnce; // first key action
  final int paywallViews;
  final int paymentAttempts;
  final String plan; // 'none', 'monthly', 'yearly', 'lifetime'
  final DateTime? subscribedAt;
  final bool testPurchase;
  final List<AdminPayment> payments;
  final List<PayFail> payFails;
  final Map<String, String> answers; // what they told us in onboarding
  final List<AdminEvent> events; // newest first
  final int streak;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.country,
    required this.isGuest,
    required this.installedAt,
    required this.joinedAt,
    required this.lastSeen,
    required this.uninstalledAt,
    required this.heardFrom,
    required this.onboardingSeconds,
    required this.onboardingDone,
    required this.committed,
    required this.prayedOnce,
    required this.paywallViews,
    required this.paymentAttempts,
    required this.plan,
    required this.subscribedAt,
    required this.testPurchase,
    required this.payments,
    required this.payFails,
    required this.answers,
    required this.events,
    required this.streak,
  });

  /// The real name. If none, the real email. If neither, "Guest" + 6 letters
  /// of the account id. Names are never invented.
  String get displayName {
    final n = name?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final e = email?.trim() ?? '';
    if (e.isNotEmpty) return e;
    return 'Guest ${id.substring(0, min(6, id.length))}';
  }

  String get initials {
    final n = name?.trim() ?? '';
    if (n.isNotEmpty) {
      final parts = n.split(RegExp(r'\s+'));
      final a = parts.first[0];
      final b = parts.length > 1 ? parts.last[0] : '';
      return (a + b).toUpperCase();
    }
    final e = email?.trim() ?? '';
    if (e.isNotEmpty) return e[0].toUpperCase();
    return 'G';
  }

  bool get subscribed => plan != 'none';
  double get paid => payments.fold(0.0, (a, p) => a + p.amount);
  bool get uninstalled => uninstalledAt != null;
  bool get signedUp => !isGuest;

  List<AdminEvent> eventsOn(DateTime day) =>
      events.where((e) => _sameDay(e.at, day)).toList();

  bool activeOn(DateTime day) =>
      events.any((e) => _sameDay(e.at, day) && e.type != 'uninstalled');

  int get prayerCount =>
      events.where((e) => e.type.startsWith('prayer_')).length;

  /// Which funnel steps this person reached (see [AdminStats.funnelSteps]).
  bool reached(String step) => switch (step) {
    'installed' => true,
    'opened' => true,
    'onboarding' => onboardingDone,
    'committed' => committed,
    'signup' => committed && (paywallViews > 0 || !isGuest),
    'paywall' => paywallViews > 0,
    'tried' => paymentAttempts > 0,
    'subscribed' => subscribed,
    'prayed' => prayedOnce,
    _ => false,
  };
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Decides who is hidden when "Real users only" is on.
/// Returns the reason in plain words, or null if the person is real.
String? hiddenReason(AdminUser u) {
  final email = (u.email ?? '').toLowerCase();
  if (email.isNotEmpty &&
      AdminConfig.adminEmails.any((e) => e.toLowerCase() == email)) {
    return 'Your own account';
  }
  if (email.isNotEmpty &&
      AdminConfig.reviewEmails.any((e) => e.toLowerCase() == email)) {
    return 'Play review login';
  }
  if (email.isNotEmpty &&
      AdminConfig.robotDomains.any(
        (d) => email.endsWith('@${d.toLowerCase()}'),
      )) {
    return 'Google test robot';
  }
  final name = (u.name ?? '').toLowerCase();
  if (name.isNotEmpty &&
      AdminConfig.reviewEmails.any((e) => e.toLowerCase() == name)) {
    return 'Play review robot';
  }
  if (RegExp(r'^testuser\d+@').hasMatch(email)) return 'Automated test';
  if (u.testPurchase) return 'Test purchase';
  final s = u.onboardingSeconds;
  if (s != null && s < AdminConfig.minOnboardingSeconds)
    return 'Looks like a robot';
  return null;
}

class FunnelStep {
  final String key;
  final String label;
  final int count;
  final double percent; // of installed people
  const FunnelStep(this.key, this.label, this.count, this.percent);
}

class AdminStats {
  final int totalUsers;
  final int subscribedUsers;
  final int activeToday;
  final double revenue30d;
  final double profitBefore;
  final double profitAfter;
  final List<FunnelStep> funnel;

  /// The step where the most people leave (step index in [funnel]), or null.
  final int? biggestDrop;

  const AdminStats({
    required this.totalUsers,
    required this.subscribedUsers,
    required this.activeToday,
    required this.revenue30d,
    required this.profitBefore,
    required this.profitAfter,
    required this.funnel,
    required this.biggestDrop,
  });

  static const funnelSteps = [
    ('installed', 'Installed'),
    ('opened', 'Opened the app'),
    ('onboarding', 'Finished onboarding'),
    ('committed', 'Committed to Jesus'),
    ('signup', 'Signed up or guest'),
    ('paywall', 'Saw the paywall'),
    ('tried', 'Tried to pay'),
    ('subscribed', 'Subscribed'),
    ('prayed', 'First prayer'),
  ];

  factory AdminStats.from(List<AdminUser> users, {DateTime? now}) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = now.subtract(const Duration(days: 30));

    final payments = users
        .expand((u) => u.payments)
        .where((p) => p.at.isAfter(from))
        .toList();
    final revenue = payments.fold(0.0, (a, p) => a + p.amount);
    final prayers30 = users
        .expand((u) => u.events)
        .where((e) => e.type.startsWith('prayer_') && e.at.isAfter(from))
        .length;
    final costs =
        prayers30 * AdminConfig.aiCostPerPrayer + AdminConfig.fixedCostPerMonth;

    final total = users.length;
    final steps = <FunnelStep>[];
    int? worst;
    var worstLoss = 0;
    var prev = total;
    for (var i = 0; i < funnelSteps.length; i++) {
      final s = funnelSteps[i];
      final c = users.where((u) => u.reached(s.$1)).length;
      steps.add(FunnelStep(s.$1, s.$2, c, total == 0 ? 0 : c / total));
      if (i > 0 && prev - c > worstLoss) {
        worstLoss = prev - c;
        worst = i;
      }
      prev = c;
    }

    return AdminStats(
      totalUsers: total,
      subscribedUsers: users.where((u) => u.subscribed).length,
      activeToday: users.where((u) => u.activeOn(today)).length,
      revenue30d: revenue,
      profitBefore: revenue - costs,
      profitAfter: revenue * (1 - AdminConfig.storeCut) - costs,
      funnel: steps,
      biggestDrop: worst,
    );
  }
}

abstract class AdminRepository {
  Future<List<AdminUser>> loadUsers();
  Future<List<AdminFeedback>> loadFeedback();
}

class AdminFeedback {
  final String id;
  final String from; // display name
  final DateTime at;
  final String kind; // 'feedback' or 'bug'
  final String text;
  final String? userId;
  bool handled;
  AdminFeedback(
    this.id,
    this.from,
    this.at,
    this.kind,
    this.text,
    this.userId, {
    this.handled = false,
  });
}

/// Made-up people so the panel can be seen before a real backend exists.
/// A few accounts are made to be hidden (my own, review team, robots).
class MockAdminRepository implements AdminRepository {
  static const yearly = PurchaseService.yearlyUsd;
  static const monthly = PurchaseService.monthlyUsd;
  static const lifetime = PurchaseService.lifetimeUsd;

  List<AdminUser>? _cache;
  List<AdminFeedback>? _feedback;

  @override
  Future<List<AdminUser>> loadUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _cache ??= _build();
  }

  @override
  Future<List<AdminFeedback>> loadFeedback() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final users = await loadUsers();
    return _feedback ??= _buildFeedback(users);
  }

  static const _names = [
    'Maria Santos',
    'David Okafor',
    'Grace Thomas',
    'Samuel Mensah',
    'Aisha Khan',
    'Joshua Miller',
    'Priya Nair',
    'Daniel Costa',
    'Esther Wanjiru',
    'Michael Brown',
    'Hannah Lee',
    'Peter Joseph',
    'Rebecca Adams',
    'Mark Fernandes',
    'Ruth Mwangi',
    'Joel Carter',
    'Naomi George',
    'Caleb Reyes',
    'Lydia Evans',
    'Isaac Dsouza',
    'Abigail Cruz',
    'Jonathan Roy',
    'Sarah Williams',
    'Matthew Silva',
    'Deborah Ade',
    'Andrew Kim',
    'Mercy Banda',
    'Philip Das',
    'Tabitha Moore',
    'Stephen Lopez',
    'Leah Thompson',
    'Timothy Nwosu',
    'Miriam Paul',
    'Aaron Shah',
    'Eunice Kamau',
    'Gabriel Santos',
    'Joy Patel',
    'Nathan Cole',
    'Faith Okoro',
    'Luke Mathew',
    'Anna Berg',
    'Simon Peter',
    'Dorcas Obi',
    'Jacob Ellis',
    'Elizabeth Jose',
    'Ethan Clarke',
    'Charity Njoroge',
    'Benjamin Rao',
    'Tessa Hall',
    'Victor Dias',
  ];
  static const _countries = [
    'India',
    'United Kingdom',
    'United States',
    'Nigeria',
    'Brazil',
    'Philippines',
    'Kenya',
    'Canada',
    'Ghana',
    'Australia',
  ];
  static const _sources = [
    'TikTok',
    'Instagram',
    'YouTube',
    'Facebook',
    'App Store or Play Store',
    'Friend or family',
    'Church',
    'Other',
  ];
  static const _sourceWeights = [26, 22, 14, 6, 12, 10, 7, 3];
  static const _habits = ['Often', 'Sometimes', 'Rarely'];
  static const _goalList = [
    'Praying every day',
    'Peace of mind',
    'Gratitude',
    'Guidance',
    'A closer walk with God',
  ];

  String _pickSource(Random r) {
    var n = r.nextInt(_sourceWeights.reduce((a, b) => a + b));
    for (var i = 0; i < _sources.length; i++) {
      n -= _sourceWeights[i];
      if (n < 0) return _sources[i];
    }
    return _sources.last;
  }

  List<AdminUser> _build() {
    final r = Random(7);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final users = <AdminUser>[];

    // 130 people, many with only a guest account or only an email.
    for (var i = 0; i < 130; i++) {
      final daysAgo = r.nextInt(30);
      final installed = now.subtract(
        Duration(days: daysAgo, hours: r.nextInt(20), minutes: r.nextInt(60)),
      );
      final base = _names[i % _names.length];
      final kind = r.nextDouble();
      final isGuest = kind < 0.18;
      String? name = isGuest ? null : base;
      String? email = isGuest
          ? null
          : '${base.toLowerCase().replaceAll(' ', '.')}${i >= _names.length ? i : ''}@gmail.com';
      if (!isGuest && kind < 0.30) name = null; // gave only an email
      users.add(_person(r, now, today, i, installed, name, email, isGuest));
    }

    // Accounts that must be hidden when "Real users only" is on.
    users.add(
      _special(
        r,
        now,
        'own1',
        'Sidharth Babu',
        'sidharthbabu9@gmail.com',
        onboardingSeconds: 140,
        sub: 'yearly',
        test: false,
        daysAgo: 12,
      ),
    );
    users.add(
      _special(
        r,
        now,
        'rev001',
        null,
        'playreview.login@gmail.com',
        onboardingSeconds: 90,
        sub: 'none',
        test: false,
        daysAgo: 6,
      ),
    );
    users.add(
      _special(
        r,
        now,
        'rev002',
        'playreview.login@gmail.com',
        'testuser48213@gmail.com',
        onboardingSeconds: 80,
        sub: 'none',
        test: false,
        daysAgo: 6,
      ),
    );
    for (var k = 0; k < 3; k++) {
      users.add(
        _special(
          r,
          now,
          'rob00$k',
          null,
          'pre-launch-${1000 + k}@cloudtestlabaccounts.com',
          onboardingSeconds: 9 + k,
          sub: 'none',
          test: false,
          daysAgo: 4 + k,
        ),
      );
    }
    users.add(
      _special(
        r,
        now,
        'tp0001',
        'Sam Tester',
        'sam.tester@gmail.com',
        onboardingSeconds: 120,
        sub: 'monthly',
        test: true,
        daysAgo: 9,
      ),
    );
    users.add(
      _special(
        r,
        now,
        'fast01',
        'Quick Account',
        'quick.account@gmail.com',
        onboardingSeconds: 14,
        sub: 'none',
        test: false,
        daysAgo: 2,
      ),
    );

    users.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return users;
  }

  AdminUser _person(
    Random r,
    DateTime now,
    DateTime today,
    int i,
    DateTime installed,
    String? name,
    String? email,
    bool isGuest,
  ) {
    final id =
        (0x3f9a2c + i * 7919).toRadixString(16).padLeft(6, '0') + 'a${i}b2c';
    final joined = installed.add(Duration(minutes: 3 + r.nextInt(8)));
    final doneOnboarding = r.nextDouble() < 0.82;
    final committed = doneOnboarding && r.nextDouble() < 0.88;
    final signedUp = committed && !isGuest;
    final guestCommitted = committed && isGuest;
    final reachedAuth = committed && r.nextDouble() < 0.9;
    // Guests also pass the sign up screen (as guest). Count as "created account" only if not guest.
    final views = reachedAuth ? 1 + r.nextInt(3) : 0;
    final tried = views > 0 && r.nextDouble() < 0.5;
    final attempts = tried ? 1 + r.nextInt(3) : 0;
    final subscribed = tried && r.nextDouble() < 0.62;
    final roll = r.nextDouble();
    final plan = !subscribed
        ? 'none'
        : (roll < 0.12 ? 'lifetime' : (roll < 0.62 ? 'yearly' : 'monthly'));
    final onboardingSeconds = doneOnboarding ? 70 + r.nextInt(200) : null;

    final ev = <AdminEvent>[];
    var t = joined;
    ev.add(AdminEvent(installed, 'opened', 'First launch'));
    if (doneOnboarding) {
      t = t.add(Duration(seconds: onboardingSeconds!));
      ev.add(
        AdminEvent(
          t,
          'onboarding_done',
          'Took ${onboardingSeconds ~/ 60}m ${onboardingSeconds % 60}s',
        ),
      );
    }
    if (committed) {
      t = t.add(Duration(seconds: 20 + r.nextInt(40)));
      ev.add(AdminEvent(t, 'committed', 'Held the button to the end'));
    }
    if (signedUp || guestCommitted) {
      t = t.add(Duration(seconds: 15 + r.nextInt(40)));
      if (!isGuest) ev.add(AdminEvent(t, 'signed_up', 'Signed up'));
    }
    final fails = <PayFail>[];
    DateTime? subAt;
    for (var v = 0; v < views; v++) {
      final at = v == 0
          ? t.add(const Duration(seconds: 12))
          : t.add(Duration(days: v, hours: r.nextInt(8)));
      if (at.isBefore(now))
        ev.add(AdminEvent(at, 'paywall_view', 'Paywall view #${v + 1}'));
    }
    for (var a = 0; a < attempts; a++) {
      final at = t.add(Duration(minutes: 1 + a * 3));
      if (at.isAfter(now)) continue;
      ev.add(AdminEvent(at, 'payment_attempt', 'Payment attempt #${a + 1}'));
      final lastTry = a == attempts - 1;
      if (!(subscribed && lastTry)) {
        final k = r.nextDouble();
        final kind = k < 0.62 ? 'cancelled' : (k < 0.88 ? 'failed' : 'store');
        fails.add(PayFail(at.add(const Duration(seconds: 25)), kind));
        ev.add(
          AdminEvent(
            at.add(const Duration(seconds: 25)),
            'payment_failed',
            payFailTitles[kind]!,
          ),
        );
      }
    }
    if (subscribed) {
      subAt = t.add(Duration(minutes: 2 + attempts * 3));
      if (subAt.isAfter(now)) subAt = now.subtract(const Duration(minutes: 5));
      ev.add(
        AdminEvent(subAt, 'subscribed', switch (plan) {
          'yearly' => 'Yearly plan, 7 day free trial',
          'monthly' => 'Monthly plan, 7 day free trial',
          _ => 'Lifetime plan, one payment, no trial',
        }),
      );
    }

    // Daily use after getting in. Subscribers use the app more.
    var streak = 0;
    var prayedOnce = false;
    final inApp = subscribed;
    final churned = r.nextDouble() < (subscribed ? 0.15 : 0.5);
    final daysActive = installed.difference(today).inDays.abs();
    final lastDayOffset = churned
        ? r.nextInt(max(1, daysActive + 1))
        : r.nextInt(2);
    final lastDay = today.subtract(Duration(days: lastDayOffset));
    final firstDay = DateTime(installed.year, installed.month, installed.day);
    if (inApp) {
      final p = subscribed ? 0.8 : 0.3;
      for (
        var d = firstDay;
        !d.isAfter(lastDay);
        d = d.add(const Duration(days: 1))
      ) {
        if (d != firstDay && r.nextDouble() > p) continue;
        DateTime at(int h, int m) {
          final x = d.add(Duration(hours: h, minutes: m + r.nextInt(25)));
          return x.isAfter(now)
              ? now.subtract(Duration(minutes: 3 + r.nextInt(50)))
              : x;
        }

        if (subAt != null && at(7, 0).isBefore(subAt)) continue;
        final isToday = d == today;
        if (r.nextDouble() < 0.8 && (!isToday || now.hour >= 7)) {
          ev.add(AdminEvent(at(7, 0), 'prayer_morning', 'Felt ${_feel(r)}'));
          prayedOnce = true;
        }
        if (r.nextDouble() < 0.7 && (!isToday || now.hour >= 22)) {
          ev.add(AdminEvent(at(21, 30), 'prayer_night', 'Felt ${_feel(r)}'));
          prayedOnce = true;
        }
        for (var g = r.nextInt(3); g > 0; g--) {
          if (!isToday || now.hour >= 11) {
            ev.add(
              AdminEvent(
                at(11 + r.nextInt(8), 0),
                'prayer_gate',
                'Before ${_app(r)}',
              ),
            );
            prayedOnce = true;
          }
        }
        if (r.nextDouble() < 0.12) {
          ev.add(
            AdminEvent(
              at(9, 30),
              'apps_locked',
              '${3 + r.nextInt(12)} apps locked',
            ),
          );
        }
        ev.add(AdminEvent(at(6, 40), 'opened', 'Opened the app'));
      }
      for (var k = 0; k < 40; k++) {
        final d = lastDay.subtract(Duration(days: k));
        final has = ev.any(
          (e) => e.type.startsWith('prayer_') && _sameDay(e.at, d),
        );
        if (!has) break;
        streak++;
      }
    } else if (doneOnboarding) {
      // People who did not subscribe still opened the app on a few days.
      for (
        var d = firstDay;
        !d.isAfter(lastDay);
        d = d.add(const Duration(days: 1))
      ) {
        if (d != firstDay && r.nextDouble() > 0.2) continue;
        final x = d.add(
          Duration(hours: 8 + r.nextInt(12), minutes: r.nextInt(50)),
        );
        if (x.isBefore(now)) ev.add(AdminEvent(x, 'opened', 'Opened the app'));
      }
    }

    // Uninstall: people who did not subscribe leave far more often.
    DateTime? uninstalledAt;
    if (r.nextDouble() < (subscribed ? 0.05 : 0.22)) {
      final lastEvent = ev
          .map((e) => e.at)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final u = lastEvent.add(Duration(hours: 4 + r.nextInt(60)));
      if (u.isBefore(now)) {
        uninstalledAt = u;
        ev.add(
          AdminEvent(u, 'uninstalled', 'Google stopped accepting this phone'),
        );
      }
    }

    ev.sort((a, b) => b.at.compareTo(a.at));
    final seen = ev.first.at;

    final pay = <AdminPayment>[];
    if (subAt != null && plan == 'lifetime') {
      pay.add(AdminPayment(subAt, lifetime));
    } else if (subAt != null) {
      var next = subAt.add(const Duration(days: 7));
      while (!next.isAfter(now)) {
        pay.add(AdminPayment(next, plan == 'yearly' ? yearly : monthly));
        if (plan == 'yearly') break;
        next = next.add(const Duration(days: 30));
      }
    }

    final goalsN = 1 + r.nextInt(3);
    final goals = (List.of(_goalList)..shuffle(r)).take(goalsN).toList();
    final heard = doneOnboarding ? _pickSource(r) : null;

    return AdminUser(
      id: id,
      name: name,
      email: email,
      country: _countries[r.nextInt(_countries.length)],
      isGuest: isGuest,
      installedAt: installed,
      joinedAt: joined,
      lastSeen: seen,
      uninstalledAt: uninstalledAt,
      heardFrom: heard,
      onboardingSeconds: onboardingSeconds,
      onboardingDone: doneOnboarding,
      committed: committed,
      prayedOnce: prayedOnce,
      paywallViews: views,
      paymentAttempts: attempts,
      plan: plan,
      subscribedAt: subAt,
      testPurchase: false,
      payments: pay,
      payFails: fails,
      answers: doneOnboarding
          ? {
              'Phone gets attention before Jesus?': _habits[r.nextInt(3)],
              'What they want most': goals.join(', '),
              'Morning prayer time':
                  '${6 + r.nextInt(3)}:${r.nextBool() ? '00' : '30'} AM',
              'Night prayer time':
                  '${9 + r.nextInt(2)}:${r.nextBool() ? '00' : '30'} PM',
              'Heard about us from': heard ?? '',
            }
          : const {},
      events: ev,
      streak: streak,
    );
  }

  AdminUser _special(
    Random r,
    DateTime now,
    String id,
    String? name,
    String email, {
    required int onboardingSeconds,
    required String sub,
    required bool test,
    required int daysAgo,
  }) {
    final installed = now.subtract(Duration(days: daysAgo, hours: 2));
    final ev = <AdminEvent>[
      AdminEvent(installed, 'opened', 'First launch'),
      AdminEvent(
        installed.add(Duration(seconds: onboardingSeconds)),
        'onboarding_done',
        'Took ${onboardingSeconds}s',
      ),
      AdminEvent(
        now.subtract(Duration(hours: 1 + r.nextInt(30))),
        'opened',
        'Opened the app',
      ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    final subAt = sub == 'none'
        ? null
        : installed.add(const Duration(minutes: 6));
    return AdminUser(
      id: id.padRight(8, '0'),
      name: name,
      email: email,
      country: 'India',
      isGuest: false,
      installedAt: installed,
      joinedAt: installed.add(const Duration(minutes: 3)),
      lastSeen: ev.first.at,
      uninstalledAt: null,
      heardFrom: 'Other',
      onboardingSeconds: onboardingSeconds,
      onboardingDone: true,
      committed: true,
      prayedOnce: sub != 'none',
      paywallViews: 1,
      paymentAttempts: sub == 'none' ? 0 : 1,
      plan: sub,
      subscribedAt: subAt,
      testPurchase: test,
      payments: subAt == null
          ? const []
          : [
              AdminPayment(
                subAt.add(const Duration(days: 7)),
                sub == 'yearly' ? yearly : monthly,
              ),
            ],
      payFails: const [],
      answers: const {'Heard about us from': 'Other'},
      events: ev,
      streak: 0,
    );
  }

  List<AdminFeedback> _buildFeedback(List<AdminUser> users) {
    final real = users
        .where((u) => hiddenReason(u) == null && u.prayedOnce)
        .toList();
    AdminUser p(int i) => real[i % real.length];
    final now = DateTime.now();
    return [
      AdminFeedback(
        'f1',
        p(2).displayName,
        now.subtract(const Duration(hours: 3)),
        'feedback',
        'I love the 10 second prayer before Instagram. It really slows me down. Thank you!',
        p(2).id,
      ),
      AdminFeedback(
        'f2',
        p(5).displayName,
        now.subtract(const Duration(hours: 20)),
        'bug',
        'After I pray, the button does not open the app I wanted. I have to open it myself.',
        p(5).id,
      ),
      AdminFeedback(
        'f3',
        p(9).displayName,
        now.subtract(const Duration(days: 2)),
        'feedback',
        'Please add more Bible verses for the night prayer.',
        p(9).id,
      ),
      AdminFeedback(
        'f4',
        p(14).displayName,
        now.subtract(const Duration(days: 3)),
        'bug',
        'The morning reminder came at the wrong time after I changed my time zone.',
        p(14).id,
        handled: true,
      ),
      AdminFeedback(
        'f5',
        p(21).displayName,
        now.subtract(const Duration(days: 6)),
        'feedback',
        'Great app. Could there be a family plan?',
        p(21).id,
        handled: true,
      ),
    ];
  }

  static String _feel(Random r) => const [
    'grateful',
    'hopeful',
    'peaceful',
    'tired',
    'anxious',
    'stressed',
  ][r.nextInt(6)];
  static String _app(Random r) => const [
    'Instagram',
    'TikTok',
    'YouTube',
    'WhatsApp',
    'Facebook',
    'X',
  ][r.nextInt(6)];
}
