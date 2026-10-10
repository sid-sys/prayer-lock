import 'dart:math';

/// Everything the admin panel shows is built from a list of [AdminUser].
/// Today the list is made up (MockAdminRepository). Later a real repository
/// can read the same shape from Firestore, and the screens stay the same.

class AdminEvent {
  final DateTime at;
  final String type;
  final String detail;
  const AdminEvent(this.at, this.type, this.detail);

  String get emoji => switch (type) {
        'onboarding_done' => '✅',
        'committed' => '🙏',
        'paywall_view' => '💳',
        'payment_attempt' => '🧾',
        'subscribed' => '👑',
        'prayer_morning' => '🌅',
        'prayer_night' => '🌙',
        'prayer_gate' => '🔒',
        'apps_locked' => '📵',
        'opened' => '👋',
        _ => '•',
      };

  String get title => switch (type) {
        'onboarding_done' => 'Finished onboarding',
        'committed' => 'Committed devotion to Jesus',
        'paywall_view' => 'Reached the paywall',
        'payment_attempt' => 'Tried to pay',
        'subscribed' => 'Subscribed',
        'prayer_morning' => 'Morning prayer',
        'prayer_night' => 'Night prayer',
        'prayer_gate' => 'Prayer before opening an app',
        'apps_locked' => 'Locked apps',
        'opened' => 'Opened the app',
        _ => type,
      };
}

class AdminPayment {
  final DateTime at;
  final double amount;
  const AdminPayment(this.at, this.amount);
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String country;
  final DateTime joinedAt;
  final DateTime lastSeen;
  final bool onboardingComplete;
  final bool committed;
  final int paywallViews;
  final int paymentAttempts;
  final String plan; // 'none', 'monthly', 'yearly'
  final DateTime? subscribedAt;
  final List<AdminPayment> payments;
  final List<AdminEvent> events; // newest first
  final int streak;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.country,
    required this.joinedAt,
    required this.lastSeen,
    required this.onboardingComplete,
    required this.committed,
    required this.paywallViews,
    required this.paymentAttempts,
    required this.plan,
    required this.subscribedAt,
    required this.payments,
    required this.events,
    required this.streak,
  });

  bool get subscribed => plan != 'none';
  double get paid => payments.fold(0.0, (a, p) => a + p.amount);

  List<AdminEvent> eventsOn(DateTime day) => events
      .where((e) => e.at.year == day.year && e.at.month == day.month && e.at.day == day.day)
      .toList();

  bool activeOn(DateTime day) => eventsOn(day).isNotEmpty;

  int get prayerCount => events.where((e) => e.type.startsWith('prayer_')).length;
}

class AdminStats {
  final int totalUsers;
  final int subscribedUsers;
  final int payingUsers;
  final int newUsers7d;
  final int dauToday;
  final int wau;
  final double revenueTotal;
  final double revenue30d;
  final double costs;
  final double profit;
  final double storeCutEstimate;

  /// Last 14 days, oldest first.
  final List<(DateTime, int)> dauSeries;

  /// (label, count)
  final List<(String, int)> funnel;

  const AdminStats({
    required this.totalUsers,
    required this.subscribedUsers,
    required this.payingUsers,
    required this.newUsers7d,
    required this.dauToday,
    required this.wau,
    required this.revenueTotal,
    required this.revenue30d,
    required this.costs,
    required this.profit,
    required this.storeCutEstimate,
    required this.dauSeries,
    required this.funnel,
  });

  double get conversion => totalUsers == 0 ? 0 : subscribedUsers / totalUsers;

  factory AdminStats.from(List<AdminUser> users, {DateTime? now}) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int dau(DateTime d) => users.where((u) => u.activeOn(d)).length;
    final series = [
      for (var i = 13; i >= 0; i--)
        (today.subtract(Duration(days: i)), dau(today.subtract(Duration(days: i)))),
    ];

    final wau = users
        .where((u) => List.generate(7, (i) => today.subtract(Duration(days: i)))
            .any(u.activeOn))
        .length;

    final allPayments = users.expand((u) => u.payments).toList();
    final revenueTotal = allPayments.fold(0.0, (a, p) => a + p.amount);
    final revenue30d = allPayments
        .where((p) => p.at.isAfter(now!.subtract(const Duration(days: 30))))
        .fold(0.0, (a, p) => a + p.amount);

    // Costs we pay: AI prayers (about $0.0001 each) and fixed fees (about $12 a month).
    final prayers = users.fold(0, (a, u) => a + u.prayerCount);
    final firstJoin = users.isEmpty
        ? now
        : users.map((u) => u.joinedAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final months = max(1.0, now.difference(firstJoin).inDays / 30);
    final costs = prayers * 0.0001 + months * 12;

    return AdminStats(
      totalUsers: users.length,
      subscribedUsers: users.where((u) => u.subscribed).length,
      payingUsers: users.where((u) => u.payments.isNotEmpty).length,
      newUsers7d: users.where((u) => u.joinedAt.isAfter(now!.subtract(const Duration(days: 7)))).length,
      dauToday: dau(today),
      wau: wau,
      revenueTotal: revenueTotal,
      revenue30d: revenue30d,
      costs: costs,
      profit: revenueTotal - costs,
      storeCutEstimate: revenueTotal * 0.15,
      dauSeries: series,
      funnel: [
        ('Joined', users.length),
        ('Finished onboarding', users.where((u) => u.onboardingComplete).length),
        ('Committed to Jesus', users.where((u) => u.committed).length),
        ('Reached paywall', users.where((u) => u.paywallViews > 0).length),
        ('Tried to pay', users.where((u) => u.paymentAttempts > 0).length),
        ('Subscribed', users.where((u) => u.subscribed).length),
      ],
    );
  }
}

abstract class AdminRepository {
  Future<List<AdminUser>> loadUsers();
}

/// Made-up users so the panel can be seen before a real backend exists.
class MockAdminRepository implements AdminRepository {
  static const yearly = 29.99;
  static const monthly = 9.99;

  @override
  Future<List<AdminUser>> loadUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _build();
  }

  static const _names = [
    'Maria Santos', 'David Okafor', 'Grace Thomas', 'Samuel Mensah', 'Aisha Khan',
    'Joshua Miller', 'Priya Nair', 'Daniel Costa', 'Esther Wanjiru', 'Michael Brown',
    'Hannah Lee', 'Peter Joseph', 'Rebecca Adams', 'Mark Fernandes', 'Ruth Mwangi',
    'Joel Carter', 'Naomi George', 'Caleb Reyes', 'Lydia Evans', 'Isaac Dsouza',
    'Abigail Cruz', 'Jonathan Roy', 'Sarah Williams', 'Matthew Silva', 'Deborah Ade',
    'Andrew Kim', 'Mercy Banda', 'Philip Das', 'Tabitha Moore', 'Stephen Lopez',
    'Leah Thompson', 'Timothy Nwosu', 'Miriam Paul', 'Aaron Shah', 'Eunice Kamau',
    'Gabriel Santos', 'Joy Patel', 'Nathan Cole', 'Faith Okoro', 'Luke Mathew',
    'Anna Berg', 'Simon Peter', 'Dorcas Obi', 'Jacob Ellis', 'Elizabeth Jose',
    'Ethan Clarke', 'Charity Njoroge', 'Benjamin Rao', 'Tessa Hall', 'Victor Dias',
  ];
  static const _countries = ['India', 'United Kingdom', 'United States', 'Nigeria',
    'Brazil', 'Philippines', 'Kenya', 'Canada', 'Ghana', 'Australia'];

  List<AdminUser> _build() {
    final r = Random(42);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final users = <AdminUser>[];

    for (var i = 0; i < _names.length; i++) {
      final name = _names[i];
      final email = '${name.toLowerCase().replaceAll(' ', '.')}@gmail.com';
      final daysAgo = r.nextInt(45);
      final joined = now
          .subtract(Duration(days: daysAgo, hours: r.nextInt(20), minutes: r.nextInt(60)));

      final doneOnboarding = r.nextDouble() < 0.92;
      final committed = doneOnboarding && r.nextDouble() < 0.82;
      final views = committed ? 1 + r.nextInt(4) : 0;
      final tried = views > 0 && r.nextDouble() < 0.5;
      final attempts = tried ? 1 + r.nextInt(3) : 0;
      final subscribed = tried && r.nextDouble() < 0.65;
      final plan = !subscribed ? 'none' : (r.nextDouble() < 0.55 ? 'yearly' : 'monthly');

      final ev = <AdminEvent>[];
      var t = joined;
      if (doneOnboarding) {
        t = t.add(Duration(minutes: 4 + r.nextInt(6)));
        ev.add(AdminEvent(t, 'onboarding_done', 'All 6 steps'));
      }
      if (committed) {
        t = t.add(Duration(minutes: 1 + r.nextInt(2)));
        ev.add(AdminEvent(t, 'committed', 'Held the button 2.3 seconds'));
      }
      DateTime? subAt;
      for (var v = 0; v < views; v++) {
        final at = v == 0 ? t.add(const Duration(seconds: 20)) : t.add(Duration(days: v, hours: r.nextInt(8)));
        if (at.isBefore(now)) ev.add(AdminEvent(at, 'paywall_view', 'Paywall view #${v + 1}'));
      }
      for (var a = 0; a < attempts; a++) {
        final at = t.add(Duration(minutes: 1 + a * 3));
        if (at.isBefore(now)) ev.add(AdminEvent(at, 'payment_attempt', 'Payment attempt #${a + 1}'));
      }
      if (subscribed) {
        subAt = t.add(Duration(minutes: 2 + attempts * 3));
        if (subAt.isAfter(now)) subAt = now.subtract(const Duration(minutes: 5));
        ev.add(AdminEvent(subAt, 'subscribed',
            plan == 'yearly' ? 'Yearly plan, 7 day free trial' : 'Monthly plan, 7 day free trial'));
      }

      // Daily use. Subscribers use the app more. Some people stop coming.
      final churned = r.nextDouble() < (subscribed ? 0.12 : 0.4);
      final lastDayOffset = churned ? r.nextInt(max(1, daysAgo + 1)) : r.nextInt(2);
      final lastDay = today.subtract(Duration(days: lastDayOffset));
      final firstDay = DateTime(joined.year, joined.month, joined.day);
      var streak = 0;
      if (committed) {
        final p = subscribed ? 0.82 : 0.38;
        for (var d = firstDay; !d.isAfter(lastDay); d = d.add(const Duration(days: 1))) {
          if (d != firstDay && r.nextDouble() > p) continue;
          final isToday = d == today;
          DateTime at(int h, int m) {
            final x = d.add(Duration(hours: h, minutes: m + r.nextInt(25)));
            return x.isAfter(now) ? now.subtract(Duration(minutes: 3 + r.nextInt(50))) : x;
          }

          if (r.nextDouble() < 0.8 && (!isToday || now.hour >= 7)) {
            ev.add(AdminEvent(at(7, 0), 'prayer_morning', 'Felt ${_feel(r)}'));
          }
          if (r.nextDouble() < 0.7 && (!isToday || now.hour >= 22)) {
            ev.add(AdminEvent(at(21, 30), 'prayer_night', 'Felt ${_feel(r)}'));
          }
          for (var g = r.nextInt(3); g > 0; g--) {
            if (!isToday || now.hour >= 11) {
              ev.add(AdminEvent(at(11 + r.nextInt(8), 0), 'prayer_gate',
                  'Before ${_app(r)}'));
            }
          }
          if (r.nextDouble() < 0.12) {
            ev.add(AdminEvent(at(9, 30), 'apps_locked', '${3 + r.nextInt(12)} apps locked'));
          }
          if (ev.isNotEmpty) ev.add(AdminEvent(at(6, 40), 'opened', 'Session start'));
        }
        // simple streak guess: consecutive recent days with a prayer
        for (var k = 0; k < 40; k++) {
          final d = lastDay.subtract(Duration(days: k));
          final has = ev.any((e) =>
              e.type.startsWith('prayer_') &&
              e.at.year == d.year && e.at.month == d.month && e.at.day == d.day);
          if (!has) break;
          streak++;
        }
      }

      ev.sort((a, b) => b.at.compareTo(a.at));
      final seen = ev.isEmpty ? joined : ev.first.at;

      // Payments: yearly pays once after the trial, monthly every 30 days.
      final pay = <AdminPayment>[];
      if (subAt != null) {
        var next = subAt.add(const Duration(days: 7));
        while (!next.isAfter(now)) {
          pay.add(AdminPayment(next, plan == 'yearly' ? yearly : monthly));
          if (plan == 'yearly') break;
          next = next.add(const Duration(days: 30));
        }
      }

      users.add(AdminUser(
        id: 'u${1000 + i}',
        name: name,
        email: email,
        country: _countries[r.nextInt(_countries.length)],
        joinedAt: joined,
        lastSeen: seen,
        onboardingComplete: doneOnboarding,
        committed: committed,
        paywallViews: views,
        paymentAttempts: attempts,
        plan: plan,
        subscribedAt: subAt,
        payments: pay,
        events: ev,
        streak: streak,
      ));
    }
    users.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return users;
  }

  static String _feel(Random r) =>
      const ['grateful', 'hopeful', 'peaceful', 'tired', 'anxious', 'stressed'][r.nextInt(6)];
  static String _app(Random r) =>
      const ['Instagram', 'TikTok', 'YouTube', 'WhatsApp', 'Facebook', 'X'][r.nextInt(6)];
}
