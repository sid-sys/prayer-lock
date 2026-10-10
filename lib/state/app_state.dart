import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/blocker_service.dart';

class PrayerEntry {
  final DateTime date;
  final int relationship; // 1-5
  final String feeling;
  PrayerEntry(this.date, this.relationship, this.feeling);

  Map<String, dynamic> toJson() => {
        'd': date.toIso8601String(),
        'r': relationship,
        'f': feeling,
      };
  factory PrayerEntry.fromJson(Map<String, dynamic> j) =>
      PrayerEntry(DateTime.parse(j['d']), j['r'], j['f']);
}

class AppState extends ChangeNotifier {
  late SharedPreferences _p;
  List<String> lockedApps = [];
  List<PrayerEntry> history = [];
  DateTime? unlockedUntil;
  int scheduleMinutes = 0; // 0 = automatic
  bool blockingOn = true;
  bool loaded = false;

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
    loaded = true;
    notifyListeners();
  }

  bool get isUnlocked =>
      unlockedUntil != null && unlockedUntil!.isAfter(DateTime.now());

  Set<DateTime> get _days => history
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet();

  bool get prayedToday {
    final n = DateTime.now();
    return _days.contains(DateTime(n.year, n.month, n.day));
  }

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

  int get totalPrayers => history.length;

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
    // automatic = 60 minutes
    final m = minutes == 0 ? 60 : minutes;
    unlockedUntil = DateTime.now().add(Duration(minutes: m));
    await _p.setString('until', unlockedUntil!.toIso8601String());
    await _sync();
    notifyListeners();
  }

  Future<void> _sync() => BlockerService.update(
        packages: blockingOn ? lockedApps : [],
        unlockedUntil: unlockedUntil,
      );
}
