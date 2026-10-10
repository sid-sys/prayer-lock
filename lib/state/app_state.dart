import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    morningMin = _p.getInt('morningMin') ?? morningMin;
    nightMin = _p.getInt('nightMin') ?? nightMin;
    remindersOn = _p.getBool('remindersOn') ?? true;
    goals = _p.getStringList('goals') ?? [];
    loaded = true;
    notifyListeners();
  }

  // ---------- access / paywall ----------

  /// True when the user may use the app (trial running or subscribed).
  bool get entitled => trialStart != null;

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

  Future<void> rescheduleReminders() => NotificationService.schedule(
        enabled: remindersOn,
        morningMin: morningMin,
        nightMin: nightMin,
        streak: streak,
      );

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
            'Five apps on a leash. Good phone.', 'b_tamer', lockedApps.length >= 5),
        PrayerBadge('Fort Knox', 'Lock 20 apps',
            'Nobody scrolls past you.', 'b_vault', lockedApps.length >= 20),
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
    notifyListeners();
    await _p.setStringList('locked', lockedApps);
    await _sync();
  }

  Future<void> setAll(List<String> pkgs) async {
    lockedApps = pkgs;
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
    notifyListeners();
  }

  Future<void> _sync() => BlockerService.update(
        packages: blockingOn ? lockedApps : [],
        unlockedUntil: unlockedUntil,
      );
}
