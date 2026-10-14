import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../services/blocker_service.dart';
import '../services/notification_service.dart';

/// kind: 'morning', 'night' or 'gate' (prayer before opening a locked app)
class PrayerEntry {
  final DateTime date;
  final int relationship; // 1-5
  final String feeling;
  final String kind;
  final String? prayer;
  PrayerEntry(this.date, this.relationship, this.feeling,
      {this.kind = 'gate', this.prayer});

  Map<String, dynamic> toJson() => {
        'd': date.toIso8601String(),
        'r': relationship,
        'f': feeling,
        'k': kind,
        if (prayer != null) 'p': prayer,
      };
  factory PrayerEntry.fromJson(Map<String, dynamic> j) =>
      PrayerEntry(DateTime.parse(j['d']), j['r'], j['f'],
          kind: j['k'] ?? 'gate', prayer: j['p'] as String?);
}

/// One thing that happened (for the progress report). Kept on the phone only.
/// Types: gate_shown, gate_prayed, gate_abandoned, gate_continue.
class ActivityEvent {
  final DateTime at;
  final String type;
  final String? pkg;
  ActivityEvent(this.at, this.type, [this.pkg]);

  Map<String, dynamic> toJson() => {'t': at.millisecondsSinceEpoch, 'y': type, if (pkg != null) 'p': pkg};
  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
      DateTime.fromMillisecondsSinceEpoch(j['t'] as int), j['y'] as String, j['p'] as String?);
}

class PrayerBadge {
  final String title;
  final String how; // how to earn it
  final String quip; // playful line shown once earned
  final String image;
  final bool unlocked;
  const PrayerBadge(this.title, this.how, this.quip, this.image, this.unlocked);
}

class AppState extends ChangeNotifier {
  late SharedPreferences _p;
  List<String> lockedApps = [];
  List<PrayerEntry> history = [];
  DateTime? unlockedUntil;
  int scheduleMinutes = 0; // 0 = automatic
  bool blockingOn = true;
  bool loaded = false;

  bool onboarded = false;
  List<ActivityEvent> events = [];
  DateTime? lastActiveAt;
  Map<String, Map<String, int>> usageDaily = {}; // day -> app -> minutes
  bool hasUsageAccess = false;
  int iosChosen = 0; // iPhone: apps + categories + websites chosen in Apple's picker
  Set<String> seenBadges = {}; // badges already celebrated
  final List<PrayerBadge> _badgeQueue = [];
  bool committed = false; // held the "commit my devotion" button
  int paywallViews = 0;
  int paymentAttempts = 0;
  bool cancelled = false; // plan will not renew
  DateTime? accessUntil; // when access ends after cancelling
  DateTime? trialStart;
  String plan = 'yearly';
  int morningMin = 7 * 60;
  int nightMin = 21 * 60 + 30;
  bool remindersOn = true;
  List<String> goals = [];

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    lockedApps = _p.getStringList('locked') ?? [];
    scheduleMinutes = _p.getInt('schedule') ?? 0;
    blockingOn = _p.getBool('blockingOn') ?? true;
    final u = _p.getString('until');
    unlockedUntil = u == null ? null : DateTime.tryParse(u);
    history = (_p.getStringList('history') ?? [])
        .map((s) => PrayerEntry.fromJson(jsonDecode(s)))
        .toList();
    onboarded = _p.getBool('onboarded') ?? false;
    final t = _p.getString('trialStart');
    trialStart = t == null ? null : DateTime.tryParse(t);
    plan = _p.getString('plan') ?? 'yearly';
    iosChosen = _p.getInt('iosChosen') ?? 0;
    final ev = _p.getString('events');
    if (ev != null) {
      try {
        events = (jsonDecode(ev) as List)
            .map((e) => ActivityEvent.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
    final la = _p.getString('lastActiveAt');
    lastActiveAt = la == null ? null : DateTime.tryParse(la);
    final ud = _p.getString('usageDaily');
    if (ud != null) {
      try {
        usageDaily = (jsonDecode(ud) as Map).map((k, v) =>
            MapEntry(k as String, (v as Map).map((a, b) => MapEntry(a as String, (b as num).toInt()))));
      } catch (_) {}
    }
    committed = _p.getBool('committed') ?? false;
    paywallViews = _p.getInt('paywallViews') ?? 0;
    paymentAttempts = _p.getInt('paymentAttempts') ?? 0;
    cancelled = _p.getBool('cancelled') ?? false;
    final au = _p.getString('accessUntil');
    accessUntil = au == null ? null : DateTime.tryParse(au);
    morningMin = _p.getInt('morningMin') ?? morningMin;
    nightMin = _p.getInt('nightMin') ?? nightMin;
    remindersOn = _p.getBool('remindersOn') ?? true;
    goals = _p.getStringList('goals') ?? [];
    if (kDemoData) _seedDemo();
    final seen = _p.getStringList('seenBadges');
    if (seen == null) {
      seenBadges = badges.where((b) => b.unlocked).map((b) => b.title).toSet();
      await _p.setStringList('seenBadges', seenBadges.toList());
    } else {
      seenBadges = seen.toSet();
    }
    loaded = true;
    notifyListeners();
  }

  // ---------- access / paywall ----------

  /// True when the user may use the app (trial running or subscribed).
  /// Lifetime buyers pay once. No trial, no renewal, no cancelling.
  bool get isLifetime => plan == 'lifetime' && trialStart != null;

  bool get entitled {
    if (trialStart == null) return false;
    if (isLifetime) return true;
    if (cancelled && accessUntil != null && DateTime.now().isAfter(accessUntil!)) {
      return false;
    }
    return true;
  }

  bool get inTrial =>
      !isLifetime && trialStart != null && DateTime.now().isBefore(trialEnds!);

  int get trialDaysLeft =>
      inTrial ? trialEnds!.difference(DateTime.now()).inDays + 1 : 0;

  /// When the plan renews (or ends, if cancelled). Mock billing: one period
  /// after the trial.
  DateTime get nextBilling {
    final base = trialEnds ?? DateTime.now();
    final period = Duration(days: plan == 'yearly' ? 365 : 30);
    var d = base;
    while (d.isBefore(DateTime.now())) {
      d = d.add(period);
    }
    return d;
  }

  // ---------- badge toasts ----------

  bool get hasBadgeToast => _badgeQueue.isNotEmpty;

  PrayerBadge? takeBadge() => _badgeQueue.isEmpty ? null : _badgeQueue.removeAt(0);

  /// Show a toast for this badge (also used by the test tools).
  void queueBadge(PrayerBadge b) {
    _badgeQueue.add(b);
    notifyListeners();
  }

  /// Find badges that were just earned. The toast widget shows them.
  void _checkBadges() {
    var changed = false;
    for (final b in badges) {
      if (b.unlocked && !seenBadges.contains(b.title)) {
        seenBadges.add(b.title);
        _badgeQueue.add(b);
        changed = true;
      }
    }
    if (changed) _p.setStringList('seenBadges', seenBadges.toList());
  }

  Future<void> commit() async {
    committed = true;
    await _p.setBool('committed', true);
    notifyListeners();
  }

  Future<void> logPaywallView() async {
    paywallViews++;
    await _p.setInt('paywallViews', paywallViews);
  }

  Future<void> logPaymentAttempt() async {
    paymentAttempts++;
    await _p.setInt('paymentAttempts', paymentAttempts);
  }

  /// Move to another plan. Mock billing: nothing is charged.
  Future<void> changePlan(String planId) async {
    plan = planId;
    cancelled = false;
    accessUntil = null;
    await _p.setString('plan', planId);
    await _p.setBool('cancelled', false);
    await _p.remove('accessUntil');
    notifyListeners();
  }

  Future<void> cancelPlan() async {
    if (isLifetime) return; // nothing to cancel
    cancelled = true;
    accessUntil = nextBilling; // keeps access until the paid period ends
    await _p.setBool('cancelled', true);
    await _p.setString('accessUntil', accessUntil!.toIso8601String());
    notifyListeners();
  }

  Future<void> resumePlan() async {
    cancelled = false;
    accessUntil = null;
    await _p.setBool('cancelled', false);
    await _p.remove('accessUntil');
    notifyListeners();
  }

  /// TEST ONLY: show onboarding, the commit screen and the paywall again.
  /// Prayers and locked apps stay.
  Future<void> redoOnboarding() async {
    onboarded = false;
    committed = false;
    trialStart = null;
    cancelled = false;
    accessUntil = null;
    paywallViews = 0;
    paymentAttempts = 0;
    await _p.setBool('onboarded', false);
    await _p.setBool('committed', false);
    await _p.remove('trialStart');
    await _p.setBool('cancelled', false);
    await _p.remove('accessUntil');
    await _p.setInt('paywallViews', 0);
    await _p.setInt('paymentAttempts', 0);
    notifyListeners();
  }

  /// TEST ONLY: get past the paywall without paying.
  Future<void> testSkipPaywall() async {
    trialStart = DateTime.now();
    await _p.setString('trialStart', trialStart!.toIso8601String());
    notifyListeners();
  }

  /// Wipe everything on this phone (used after deleting the account).
  Future<void> resetAll() async {
    await _p.clear();
    lockedApps = [];
    history = [];
    unlockedUntil = null;
    scheduleMinutes = 0;
    blockingOn = true;
    onboarded = false;
    committed = false;
    paywallViews = 0;
    paymentAttempts = 0;
    cancelled = false;
    accessUntil = null;
    trialStart = null;
    plan = 'yearly';
    goals = [];
    await _sync();
    notifyListeners();
  }

  /// Sample data for store screenshots. Kept in memory only.
  void _seedDemo() {
    final now = DateTime.now();
    const feelings = ['Grateful', 'Hopeful', 'Peaceful', 'Tired', 'Anxious', 'Grateful', 'Hopeful', 'Peaceful', 'Grateful'];
    const rels = [2, 1, 3, 5, 2, 4, 5, 3, 5];
    const prayers = [
      'Good morning, Jesus. Thank You for this new day. Guide my steps, guard my heart, and help me love the people I meet today. Amen.',
      'Thank You, Jesus, for this day. I lay my worries at Your feet and ask for peaceful rest tonight. Amen.',
    ];
    history = [];
    for (var i = 8; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      history.add(PrayerEntry(day.add(const Duration(hours: 7, minutes: 5)), rels[8 - i],
          feelings[8 - i], kind: 'morning', prayer: prayers[0]));
      history.add(PrayerEntry(day.add(const Duration(hours: 21, minutes: 40)),
          rels[8 - i], feelings[(i + 2) % 9], kind: 'night', prayer: prayers[1]));
      if (i % 2 == 0) {
        history.add(PrayerEntry(day.add(const Duration(hours: 13)), 4, 'Hopeful', kind: 'gate'));
      }
    }
    history.removeWhere((e) => e.date.isAfter(now));
    events = [
      for (var i = 0; i < 32; i++)
        ActivityEvent(now.subtract(Duration(hours: 3 + i * 5)), 'gate_shown', 'com.instagram.android'),
      for (var i = 0; i < 14; i++)
        ActivityEvent(now.subtract(Duration(hours: 4 + i * 11)), 'gate_abandoned', 'com.instagram.android'),
      for (var i = 0; i < 12; i++)
        ActivityEvent(now.subtract(Duration(hours: 5 + i * 13)), 'gate_prayed', 'com.instagram.android'),
    ];
    usageDaily = {
      for (var i = 0; i < 14; i++)
        '${now.subtract(Duration(days: i)).year}-${now.subtract(Duration(days: i)).month.toString().padLeft(2, '0')}-${now.subtract(Duration(days: i)).day.toString().padLeft(2, '0')}': {
          'com.instagram.android': i >= 7 ? 62 : 46,
          'com.zhiliaoapp.musically': i >= 7 ? 38 : 27,
          'com.google.android.youtube': i >= 7 ? 31 : 23,
          'com.whatsapp.w4b': i >= 7 ? 20 : 15,
        },
    };
    hasUsageAccess = true;
    lockedApps = ['com.instagram.android', 'com.zhiliaoapp.musically', 'com.google.android.youtube',
      'com.whatsapp.w4b', 'com.facebook.katana'];
  }

  DateTime? get trialEnds => trialStart?.add(const Duration(days: 7));

  /// NOTE: real store billing is not connected yet. This only saves that
  /// the user pressed the trial button. See PurchaseService.
  Future<void> startTrial(String planId) async {
    plan = planId;
    trialStart = DateTime.now();
    await _p.setString('plan', planId);
    await _p.setString('trialStart', trialStart!.toIso8601String());
    notifyListeners();
  }

  Future<void> finishOnboarding({
    required List<String> goalList,
    required int morning,
    required int night,
  }) async {
    goals = goalList;
    morningMin = morning;
    nightMin = night;
    onboarded = true;
    await _p.setStringList('goals', goals);
    await _p.setInt('morningMin', morning);
    await _p.setInt('nightMin', night);
    await _p.setBool('onboarded', true);
    notifyListeners();
  }

  // ---------- prayer times ----------

  Future<void> setTimes({int? morning, int? night}) async {
    if (morning != null) morningMin = morning;
    if (night != null) nightMin = night;
    await _p.setInt('morningMin', morningMin);
    await _p.setInt('nightMin', nightMin);
    await rescheduleReminders();
    notifyListeners();
  }

  Future<void> setRemindersOn(bool v) async {
    remindersOn = v;
    await _p.setBool('remindersOn', v);
    await rescheduleReminders();
    notifyListeners();
  }

  Future<void> rescheduleReminders() async {
    await NotificationService.schedule(
      enabled: remindersOn,
      morningMin: morningMin,
      nightMin: nightMin,
      streak: streak,
    );
    await NotificationService.scheduleComeback(
      enabled: remindersOn,
      lastActive: lastActiveAt ?? DateTime.now(),
    );
  }

  // ---------- activity for the progress report ----------

  /// The person opened Prayer Lock (or did something in it). Starts the
  /// 3-day "come back" clock again.
  Future<void> touch() async {
    lastActiveAt = DateTime.now();
    await _p.setString('lastActiveAt', lastActiveAt!.toIso8601String());
    // Make the phone match the saved state (for example, put the lock back
    // if the open time has ended).
    if (onboarded) await _sync();
    if (onboarded && entitled) await rescheduleReminders();
  }

  void logEvent(String type, [String? pkg]) {
    events.add(ActivityEvent(DateTime.now(), type, pkg));
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    events.removeWhere((e) => e.at.isBefore(cutoff));
    if (events.length > 2000) events = events.sublist(events.length - 2000);
    _p.setString('events', jsonEncode(events.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  int countEvents(String type, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return events.where((e) => e.type == type && e.at.isAfter(cutoff)).length;
  }

  /// How many times the pause screen appeared when a locked app was opened.
  int get pausesThisWeek => countEvents('gate_shown');

  /// Prayers completed in the last 7 days (measured).
  int get prayersThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return history.where((e) => e.date.isAfter(cutoff)).length;
  }

  /// We assume a skipped session would have lasted about this long.
  /// It is an ESTIMATE, not something we measure.
  static const assumedSessionMinutes = 8;

  /// Sessions the person walked away from after the pause (they did not go on).
  int get skippedSessionsThisWeek => countEvents('gate_abandoned');

  /// Estimated minutes potentially reclaimed this week. The time spent praying
  /// is NOT counted.
  int get reclaimedMinutesThisWeek => skippedSessionsThisWeek * assumedSessionMinutes;

  /// Android: read time-per-app from the phone and keep one number per day.
  Future<void> refreshUsage() async {
    hasUsageAccess = await BlockerService.hasUsageAccess();
    if (hasUsageAccess && lockedApps.isNotEmpty) {
      final fresh = await BlockerService.usageByDay(14, lockedApps);
      usageDaily.addAll(fresh);
      final keep = usageDaily.keys.toList()..sort();
      while (keep.length > 60) {
        usageDaily.remove(keep.removeAt(0));
      }
      await _p.setString('usageDaily', jsonEncode(usageDaily));
    }
    notifyListeners();
  }

  List<String> get _usageDays => usageDaily.keys.toList()..sort();

  int _dayTotal(String day) {
    final m = usageDaily[day];
    if (m == null) return 0;
    var t = 0;
    for (final e in m.entries) {
      if (lockedApps.contains(e.key) || lockedApps.isEmpty) t += e.value;
    }
    return t;
  }

  /// Minutes per locked app over the last 7 days, biggest first.
  List<MapEntry<String, int>> usageWeekByApp() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final totals = <String, int>{};
    usageDaily.forEach((day, apps) {
      final d = DateTime.tryParse(day);
      if (d == null || d.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day))) return;
      apps.forEach((pkg, min) {
        if (lockedApps.isEmpty || lockedApps.contains(pkg)) totals[pkg] = (totals[pkg] ?? 0) + min;
      });
    });
    return totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// First 7 recorded days vs the latest 7 (average minutes per day), or null
  /// if we do not have enough days yet. A MEASURED comparison, not proof of cause.
  ({double before, double now, int days})? get usageComparison {
    final days = _usageDays;
    if (days.length < 10) return null;
    double avg(List<String> d) => d.map(_dayTotal).fold<int>(0, (a, b) => a + b) / d.length;
    return (before: avg(days.take(7).toList()), now: avg(days.skip(days.length - 7).toList()), days: days.length);
  }

  /// Days of usage we have so far (to show "collecting your baseline").
  int get usageDaysRecorded => usageDaily.length;

  /// Forget all activity numbers (the person asked for it).
  Future<void> clearActivity() async {
    events = [];
    usageDaily = {};
    await _p.remove('events');
    await _p.remove('usageDaily');
    notifyListeners();
  }

  bool doneToday(String kind) {
    final n = DateTime.now();
    return history.any((e) =>
        e.kind == kind &&
        e.date.year == n.year &&
        e.date.month == n.month &&
        e.date.day == n.day);
  }

  /// Which scheduled prayer is waiting now: 'morning', 'night' or null.
  String? get dueSession {
    final n = DateTime.now();
    final mins = n.hour * 60 + n.minute;
    if (mins >= nightMin && !doneToday('night')) return 'night';
    if (mins >= morningMin && mins < nightMin && !doneToday('morning')) {
      return 'morning';
    }
    return null;
  }

  // ---------- unlock window ----------

  bool get isUnlocked =>
      unlockedUntil != null && unlockedUntil!.isAfter(DateTime.now());

  /// Re-send the lock state to the phone (used after choosing apps on iPhone).
  Future<void> relock() => _sync();

  /// Put the lock back on right away (end the open window early).
  Future<void> lockNow() async {
    unlockedUntil = null;
    await _p.remove('until');
    notifyListeners();
    await _sync();
  }

  // ---------- streak ----------

  Set<DateTime> get _days => history
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet();

  bool prayedOn(DateTime d) =>
      _days.contains(DateTime(d.year, d.month, d.day));

  bool get prayedToday => prayedOn(DateTime.now());

  int get streak {
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    final days = _days;
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(day)) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  int get bestStreak {
    final days = _days.toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  int get totalPrayers => history.length;

  // ---------- badge stats ----------

  int _count(String kind) => history.where((e) => e.kind == kind).length;

  Map<DateTime, Set<String>> get _kindsByDay {
    final m = <DateTime, Set<String>>{};
    for (final e in history) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      (m[d] ??= {}).add(e.kind);
    }
    return m;
  }

  bool get _hadFullDay => _kindsByDay.values
      .any((k) => k.contains('morning') && k.contains('night'));

  /// Longest run of days with both a morning and a night prayer.
  int get _bestFullDayRun {
    final days = _kindsByDay.entries
        .where((e) => e.value.contains('morning') && e.value.contains('night'))
        .map((e) => e.key)
        .toList()
      ..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  /// True if the user came back after 3 or more days away.
  bool get _cameBack {
    final days = _days.toList()..sort();
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays >= 4) return true;
    }
    return false;
  }

  int get _sharedFeelings => history.where((e) => e.feeling != 'Private').length;
  int get _gratefulCount => history.where((e) => e.feeling == 'Grateful').length;
  bool get _feltVeryClose => history.any((e) => e.relationship == 5);

  List<PrayerBadge> get badges => [
        PrayerBadge('First Prayer', 'Say your first prayer',
            'Every journey starts with one tiny candle.', 'badge_first', totalPrayers >= 1),
        PrayerBadge('Faithful Three', 'Pray 3 days in a row',
            'Three days! Look at you go.', 'badge_three', bestStreak >= 3),
        PrayerBadge('A Week With God', 'Reach a 7 day streak',
            'Seven days of showing up. Heaven noticed.', 'badge_week', bestStreak >= 7),
        PrayerBadge('Rooted in Faith', 'Reach a 30 day streak',
            "30 days. You're basically a tree now.", 'badge_month', bestStreak >= 30),
        PrayerBadge('Sunrise Soul', 'Pray 5 mornings',
            'Up before the scroll. Respect.', 'b_sunrise', _count('morning') >= 5),
        PrayerBadge('Good Night, Jesus', 'Pray 5 nights',
            'Tucked in by grace.', 'b_night', _count('night') >= 5),
        PrayerBadge('Full Day', 'Pray morning and night on one day',
            "Both ends of the day. Chef's kiss.", 'b_fullday', _hadFullDay),
        PrayerBadge('Bookend Week', 'Pray morning and night 7 days in a row',
            'Seven days, two prayers each. Show-off.', 'b_bookend', _bestFullDayRun >= 7),
        PrayerBadge('Scroll Stopper', 'Pray before opening a locked app 10 times',
            'You paused the scroll. Legend.', 'b_stop', _count('gate') >= 10),
        PrayerBadge('Phone Tamer', 'Lock 5 apps',
            'Five apps on a leash. Good phone.', 'b_tamer', lockedCount >= 5),
        PrayerBadge('Fort Knox', 'Lock 20 apps',
            'Nobody scrolls past you.', 'b_vault', lockedCount >= 20),
        PrayerBadge('Honest Heart', 'Share how you feel 5 times',
            'Feelings are welcome here.', 'b_honest', _sharedFeelings >= 5),
        PrayerBadge('Closer Than Close', 'Say you feel Very close to God',
            'Closeness level: cuddling.', 'b_closer', _feltVeryClose),
        PrayerBadge('Grateful Heart', 'Pick Grateful 3 times',
            'Thank-you machine, activated.', 'b_grateful', _gratefulCount >= 3),
        PrayerBadge('Comeback Kid', 'Pray again after 3 days away',
            'Welcome back. The door was never locked.', 'b_comeback', _cameBack),
        PrayerBadge('Double Digits', 'Say 10 prayers',
            'Ten prayers! Heavenly.', 'b_ten', totalPrayers >= 10),
        PrayerBadge('Two Weeks Strong', 'Reach a 14 day streak',
            'Fourteen days. Definitely not a fluke.', 'b_twoweeks', bestStreak >= 14),
        PrayerBadge('Half Century', 'Say 50 prayers',
            'Fifty prayers. Halo shining.', 'b_fifty', totalPrayers >= 50),
        PrayerBadge('Hundred Club', 'Say 100 prayers',
            'Triple digits. Angels ask for tips.', 'b_hundred', totalPrayers >= 100),
        PrayerBadge('Century Streak', 'Reach a 100 day streak',
            '100 days straight. Please write a book.', 'b_century', bestStreak >= 100),
      ];

  /// Next milestone: (target days, days left).
  (int, int) get nextMilestone {
    for (final m in const [3, 7, 14, 30, 100]) {
      if (streak < m) return (m, m - streak);
    }
    return (365, 365 - streak);
  }

  // ---------- locked apps ----------

  Future<void> toggleApp(String pkg) async {
    // Change the list first so quick taps on many apps never get lost.
    lockedApps = lockedApps.contains(pkg)
        ? (List.of(lockedApps)..remove(pkg))
        : (List.of(lockedApps)..add(pkg));
    _checkBadges();
    notifyListeners();
    await _p.setStringList('locked', lockedApps);
    await _sync();
  }

  Future<void> setAll(List<String> pkgs) async {
    lockedApps = pkgs;
    _checkBadges();
    await _p.setStringList('locked', lockedApps);
    await _sync();
    notifyListeners();
  }

  Future<void> setBlockingOn(bool v) async {
    blockingOn = v;
    await _p.setBool('blockingOn', v);
    await _sync();
    notifyListeners();
  }

  Future<void> setSchedule(int minutes) async {
    scheduleMinutes = minutes;
    await _p.setInt('schedule', minutes);
    notifyListeners();
  }

  /// Called when the user finishes a prayer.
  Future<void> completePrayer(PrayerEntry e, int minutes) async {
    history.add(e);
    await _p.setStringList(
        'history', history.map((x) => jsonEncode(x.toJson())).toList());
    final m = minutes == 0 ? 60 : minutes; // automatic = 60 minutes
    unlockedUntil = DateTime.now().add(Duration(minutes: m));
    await _p.setString('until', unlockedUntil!.toIso8601String());
    await _sync();
    await rescheduleReminders();
    _checkBadges();
    notifyListeners();
  }

  /// How many apps are locked (Android list, or iPhone picker choice).
  int get lockedCount => Platform.isIOS ? iosChosen : lockedApps.length;

  /// iPhone: remember how many things the user picked in Apple's picker.
  Future<void> setIosChosen(int n) async {
    iosChosen = n;
    await _p.setInt('iosChosen', n);
    _checkBadges();
    notifyListeners();
  }

  Future<void> _sync() => BlockerService.update(
        packages: blockingOn ? lockedApps : [],
        unlockedUntil: unlockedUntil,
        enabled: blockingOn,
      );
}
