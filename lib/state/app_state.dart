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
  PrayerEntry(this.date, this.relationship, this.feeling, {this.kind = 'gate'});

  Map<String, dynamic> toJson() => {
        'd': date.toIso8601String(),
        'r': relationship,
        'f': feeling,
        'k': kind,
      };
  factory PrayerEntry.fromJson(Map<String, dynamic> j) =>
      PrayerEntry(DateTime.parse(j['d']), j['r'], j['f'], kind: j['k'] ?? 'gate');
}

class Badge {
  final String title;
  final String how;
  final String image;
  final bool unlocked;
  const Badge(this.title, this.how, this.image, this.unlocked);
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

  List<Badge> get badges => [
        Badge('First Prayer', 'Complete your first prayer.', 'badge_first', totalPrayers >= 1),
        Badge('Faithful Three', 'Pray 3 days in a row.', 'badge_three', bestStreak >= 3),
        Badge('A Week With God', 'Reach a 7 day streak.', 'badge_week', bestStreak >= 7),
        Badge('Rooted in Faith', 'Reach a 30 day streak.', 'badge_month', bestStreak >= 30),
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
    lockedApps.contains(pkg) ? lockedApps.remove(pkg) : lockedApps.add(pkg);
    await _p.setStringList('locked', lockedApps);
    await _sync();
    notifyListeners();
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
