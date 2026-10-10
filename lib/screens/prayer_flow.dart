import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/verses.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fire.dart';
import '../widgets/mood_face.dart';

enum _Step { mood, feeling, prayer, schedule, done }

/// kind: 'morning', 'night' or 'gate'.
class PrayerFlow extends StatefulWidget {
  final String kind;
  const PrayerFlow({super.key, this.kind = 'gate'});
  @override
  State<PrayerFlow> createState() => _PrayerFlowState();
}

class _PrayerFlowState extends State<PrayerFlow> {
  _Step _step = _Step.mood;
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
    if (mounted) setState(() => _prayer = p);
  }

  Future<void> _finish() async {
    final s = context.read<AppState>();
    await s.setSchedule(_minutes);
    await s.completePrayer(
        PrayerEntry(DateTime.now(), _rel, _feeling.isEmpty ? 'Private' : _feeling, kind: widget.kind),
        _minutes);
    NotificationService.celebrate(s.streak);
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
                  icon: Icon(Icons.close, color: light ? AppColors.ink : Colors.white),
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
        _Step.mood => _moodStep(),
        _Step.feeling => _feelingStep(),
        _Step.prayer => _prayerStep(),
        _Step.schedule => _scheduleStep(),
        _Step.done => _doneStep(),
      };

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
    const colors = [AppColors.blue, AppColors.peach, AppColors.mint, AppColors.pink];
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
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (widget.kind == 'morning') ...[
                        Text('"${v.text}"',
                            textAlign: TextAlign.center,
                            style: serif(16, color: AppColors.yellow)),
                        Text(v.ref, style: const TextStyle(color: AppColors.soft)),
                        const SizedBox(height: 22),
                      ],
                      Text(_prayer!, textAlign: TextAlign.center, style: serif(23)),
                    ],
                  ),
                ),
        ),
        FilledButton(
          onPressed: _prayer == null
              ? null
              : () => setState(() => _step = _Step.schedule),
          child: Text(_doneButton),
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
                              color: _minutes == o.$1 ? AppColors.ink : Colors.white))),
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

  // 5. done
  Widget _doneStep() {
    final s = context.watch<AppState>();
    final v = verseOfDay();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AnimatedFire(size: 110),
        Text('${s.streak}', style: h(72)),
        Text(s.streak == 1 ? 'day in a row' : 'days in a row',
            style: h(18, color: AppColors.soft, w: FontWeight.w500)),
        const SizedBox(height: 28),
        Text('"${v.text}"', textAlign: TextAlign.center, style: serif(21)),
        const SizedBox(height: 8),
        Text(v.ref, style: const TextStyle(color: AppColors.yellow)),
        if (widget.kind == 'night') ...[
          const SizedBox(height: 18),
          Text('Rest peacefully. You are not alone 💛',
              style: h(16, color: AppColors.soft, w: FontWeight.w500)),
        ],
        const SizedBox(height: 36),
        FilledButton(
            onPressed: () => Navigator.pop(context), child: const Text('Amen 🙌')),
      ],
    );
  }
}
