import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import '../data/verses.dart';
import '../services/blocker_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fire.dart';
import '../widgets/mood_face.dart';
import '../widgets/praying_loader.dart';

enum _Step { intro, mood, feeling, prayer, schedule, done }

/// kind: 'morning', 'night' or 'gate'.
class PrayerFlow extends StatefulWidget {
  final String kind;

  /// Package of the locked app the user wanted. Opened after the prayer.
  final String? openAfter;
  const PrayerFlow({super.key, this.kind = 'gate', this.openAfter});
  @override
  State<PrayerFlow> createState() => _PrayerFlowState();
}

class _PrayerFlowState extends State<PrayerFlow> with SingleTickerProviderStateMixin {
  /// You must stay with the prayer for 10 seconds before the apps unlock.
  static const _prayerSeconds = 10;
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(seconds: _prayerSeconds));

  bool _completed = false;
  late final AppState _app = context.read<AppState>();
  // A locked app (or a waiting prayer) sent the person here: say why first.
  late _Step _step = widget.openAfter != null ? _Step.intro : _Step.mood;
  double _mood = 0.6;
  String _feeling = '';
  String? _prayer;
  int _minutes = 0;

  int get _rel => (_mood * 4).round() + 1; // 1..5

  @override
  void initState() {
    super.initState();
    _minutes = context.read<AppState>().scheduleMinutes;
  }

  Future<void> _loadPrayer() async {
    setState(() {
      _step = _Step.prayer;
      _prayer = null;
    });
    final p = await PrayerService.generate(_rel, _feeling, widget.kind);
    if (!mounted) return;
    setState(() => _prayer = p);
    _ring.forward(from: 0); // the 10 second count starts when the words appear
  }

  @override
  void dispose() {
    // Left before praying: the person walked away from the locked app.
    if (widget.openAfter != null && widget.kind == 'gate' && !_completed) {
      _app.logEvent('gate_abandoned', widget.openAfter);
    }
    _ring.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final s = context.read<AppState>();
    // Only a prayer that opens a locked app ("gate") touches the lock.
    final gate = widget.kind == 'gate';
    if (gate) await s.setSchedule(_minutes);
    await s.completePrayer(
        PrayerEntry(DateTime.now(), _rel, _feeling.isEmpty ? 'Private' : _feeling,
            kind: widget.kind, prayer: _prayer),
        _minutes);
    _completed = true;
    if (widget.openAfter != null && gate) {
      s.logEvent('gate_prayed', widget.openAfter, _minutes == 0 ? 60 : _minutes);
    }
    NotificationService.celebrate(s.streak);
    if (gate && s.lockedCount > 0) {
      NotificationService.unlocked(minutes: _minutes == 0 ? 60 : _minutes, ios: Platform.isIOS);
    }
    if (mounted) setState(() => _step = _Step.done);
  }

  // ---- texts by kind ----
  String get _feelingTitle => switch (widget.kind) {
        'morning' => 'What do you want to bring to God today?',
        'night' => 'What is on your heart tonight?',
        _ => 'How are you feeling today?',
      };

  String get _doneButton => switch (widget.kind) {
        'morning' => "I've prayed. Walk with me today 🌅",
        'night' => 'I leave today in Your hands 🌙',
        _ => "I've prayed today 🙏",
      };

  String get _moodTitle => widget.kind == 'night'
      ? 'How close did you feel to Jesus today?'
      : 'How is your relationship with God today?';

  @override
  Widget build(BuildContext context) {
    final light = _step == _Step.mood;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: light ? moodColor(_mood) : AppColors.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: _step == _Step.done
              ? const SizedBox()
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(_step), child: _body()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() => switch (_step) {
        _Step.intro => _introStep(),
        _Step.mood => _moodStep(),
        _Step.feeling => _feelingStep(),
        _Step.prayer => _prayerStep(),
        _Step.schedule => _scheduleStep(),
        _Step.done => _doneStep(),
      };

  // 0. why am I here? (a locked app was opened, or a prayer is waiting)
  Widget _introStep() {
    final pkg = widget.openAfter!;
    final app = pkg == 'ios' ? 'your app' : BlockerService.nameOf(pkg);
    final gate = widget.kind == 'gate';
    final title = gate
        ? '🔒 ${pkg == 'ios' ? 'Your app is' : '$app is'} locked'
        : widget.kind == 'morning'
            ? '🌅 Your morning prayer is waiting'
            : '🌙 Your night prayer is waiting';
    final body = gate
        ? 'Take a moment with God before you open it. A short prayer takes about a minute, then your apps open.'
        : 'Your apps are open. Pray now, or open $app and pray later. This prayer never locks or unlocks your apps.';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Pic(gate ? 'lock' : (widget.kind == 'morning' ? 'sun' : 'moon'), size: 120),
        const SizedBox(height: 24),
        Text(title, textAlign: TextAlign.center, style: h(30)),
        const SizedBox(height: 14),
        Text(body,
            textAlign: TextAlign.center,
            style: h(17, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.4)),
        const SizedBox(height: 36),
        FilledButton(
          onPressed: () => setState(() => _step = _Step.mood),
          child: const Text('Pray now 🙏'),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () {
            if (gate) {
              // Leave Prayer Lock. The locked app stays locked.
              SystemNavigator.pop();
            } else {
              _app.logEvent('gate_continue', pkg);
              Navigator.pop(context);
              BlockerService.launchApp(pkg);
            }
          },
          child: Text(gate ? 'Not now' : 'Later. Open $app',
              style: h(16, color: AppColors.soft, w: FontWeight.w700)),
        ),
      ],
    );
  }

  // 1. face slider
  Widget _moodStep() => Column(
        children: [
          Text(_moodTitle,
              textAlign: TextAlign.center, style: h(27, color: AppColors.ink)),
          const Spacer(),
          MoodFace(t: _mood, size: MediaQuery.of(context).size.width - 48),
          const Spacer(),
          Text('I feel', style: h(15, color: AppColors.ink, w: FontWeight.w500)),
          Text(moodWord(_mood), style: h(26, color: AppColors.ink)),
          const SizedBox(height: 8),
          MoodSlider(value: _mood, onChanged: (v) => setState(() => _mood = v)),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink, foregroundColor: Colors.white),
            onPressed: () => setState(() => _step = _Step.feeling),
            child: const Text('Next'),
          ),
        ],
      );

  // 2. feeling cards
  Widget _feelingStep() {
    const colors = [
      AppColors.blue,
      AppColors.yellow,
      AppColors.mint,
      AppColors.pink,
      Color(0xFFC9A6FF), // lavender
      Color(0xFFB8E986), // lime
      Color(0xFF8FD8FF), // sky
      Color(0xFFFFB3D9), // rose
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_feelingTitle, style: h(28)),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < PrayerService.feelings.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PastelCard(
                    color: colors[i % colors.length],
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    onTap: () {
                      _feeling = PrayerService.feelings[i].$2;
                      _loadPrayer();
                    },
                    child: Row(children: [
                      Text(PrayerService.feelings[i].$1,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text(PrayerService.feelings[i].$2,
                              style: h(20, color: AppColors.ink))),
                      const ArrowDot(),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () {
              _feeling = '';
              _loadPrayer();
            },
            child: const Text('Keep it private. Skip',
                style: TextStyle(color: AppColors.soft, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // 3. prayer
  Widget _prayerStep() {
    final v = verseOfDay();
    return Column(
      children: [
        Text(
            widget.kind == 'morning'
                ? '🌅 Good morning. Before the world asks anything of you...'
                : widget.kind == 'night'
                    ? '🌙 The day is over. You can lay your worries down.'
                    : '🙏 Read this prayer out loud',
            textAlign: TextAlign.center,
            style: h(17, color: AppColors.soft, w: FontWeight.w600)),
        const SizedBox(height: 20),
        Expanded(
          child: _prayer == null
              ? const Center(child: PrayingLoader())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(_prayer!, textAlign: TextAlign.center, style: serif(20)),
                      const SizedBox(height: 22),
                      // The verse of the day, under every prayer.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('📖 verse of the day',
                              style: h(14, color: AppColors.gold, w: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text('"${v.text}"', style: serif(16, color: AppColors.ink)),
                          const SizedBox(height: 6),
                          Text(v.ref,
                              style: h(13, color: AppColors.soft, w: FontWeight.w700)),
                        ]),
                      ),
                    ],
                  ),
                ),
        ),
        // 10 second countdown: 10 -> 0. The button opens when it reaches 0.
        AnimatedBuilder(
          animation: _ring,
          builder: (context, _) {
            final started = _prayer != null;
            final done = started && _ring.isCompleted;
            final left = started ? (_prayerSeconds * (1 - _ring.value)).ceil() : _prayerSeconds;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: started ? _ring.value : 0,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          color: AppColors.ink,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                key: ValueKey('ok'), size: 40, color: AppColors.ink)
                            : Text('$left', key: ValueKey(left), style: h(30)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  done
                      ? 'Take your time. Continue when you are ready 💛'
                      : 'Read it slowly and let it sink in…',
                  style: h(14, color: AppColors.soft, w: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  // Morning and night prayers finish here. Only a gate prayer
                  // asks when to lock again.
                  onPressed: done
                      ? () => widget.kind == 'gate'
                          ? setState(() => _step = _Step.schedule)
                          : _finish()
                      : null,
                  child: Text(done ? _doneButton : 'Keep praying… $left'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // 4. schedule
  Widget _scheduleStep() {
    return StatefulBuilder(builder: (context, set) {
      const opts = [
        (0, 'Automatic ✨'),
        (30, '30 minutes'),
        (50, '50 minutes'),
        (60, '1 hour'),
        (120, '2 hours'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When should your apps lock again? 🔒', style: h(28)),
          const SizedBox(height: 18),
          for (final o in opts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PastelCard(
                color: _minutes == o.$1 ? AppColors.mint : AppColors.card,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                onTap: () => set(() => _minutes = o.$1),
                child: Row(children: [
                  Expanded(
                      child: Text(o.$2,
                          style: h(18,
                              color: AppColors.ink))),
                  if (_minutes == o.$1) const Icon(Icons.check_circle, color: AppColors.ink),
                ]),
              ),
            ),
          const Spacer(),
          FilledButton(onPressed: _finish, child: const Text('Unlock my apps 🔓')),
        ],
      );
    });
  }


  static String _openFor(int minutes) {
    final m = minutes == 0 ? 60 : minutes;
    if (m == 60) return '1 hour';
    if (m % 60 == 0) return '${m ~/ 60} hours';
    return '$m minutes';
  }

  /// Green card shown right after praying: your apps are unlocked.
  Widget _unlockedBanner() {
    final ios = Platform.isIOS;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.mint, borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Text('🔓 Your apps are unlocked', style: h(20)),
        const SizedBox(height: 4),
        Text(
          ios
              ? 'Open for ${_openFor(_minutes)}. Now go back to the app you wanted: swipe up and hold for the app switcher, or press Home and open it. Apple does not let Prayer Lock open it for you.'
              : 'Open for ${_openFor(_minutes)}. They lock again after that.',
          textAlign: TextAlign.center,
          style: h(13.5, w: FontWeight.w600),
        ),
      ]),
    );
  }
  // 5. done
  Widget _doneStep() {
    final s = context.watch<AppState>();
    final v = verseOfDay();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.kind == 'gate' && s.lockedCount > 0) _unlockedBanner(),
        const AnimatedFire(size: 90),
        Text('${s.streak}', style: h(72)),
        Text(s.streak == 1 ? 'day in a row' : 'days in a row',
            style: h(18, color: AppColors.soft, w: FontWeight.w500)),
        const SizedBox(height: 28),
        Text('"${v.text}"', textAlign: TextAlign.center, style: serif(21)),
        const SizedBox(height: 8),
        Text(v.ref, style: const TextStyle(color: AppColors.soft)),
        if (widget.kind == 'night') ...[
          const SizedBox(height: 18),
          Text('Rest peacefully. You are not alone 💛',
              style: h(16, color: AppColors.soft, w: FontWeight.w500)),
        ],
        const SizedBox(height: 0),
        const SizedBox(height: 28),
        FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final pkg = widget.openAfter;
              if (pkg != null) {
                _app.logEvent('gate_continue', pkg);
                BlockerService.launchApp(pkg);
              }
            },
            child: Text(widget.openAfter == 'ios'
                ? 'Amen. I will go back to my app 🙌'
                : widget.openAfter != null
                    ? 'Amen. Open my app 🙌'
                    : 'Amen 🙌')),
      ],
    );
  }
}
