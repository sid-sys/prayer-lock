import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/blocker_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fire.dart';
import '../widgets/mood_face.dart';

class Onboarding extends StatefulWidget {
  /// Start on this page (used by screenshot mode).
  final int startAt;
  const Onboarding({super.key, this.startAt = 0});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with WidgetsBindingObserver {
  static const _count = 7;
  late int _i = widget.startAt;
  String? _habit;
  final Set<String> _goals = {};
  TimeOfDay _morning = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _night = const TimeOfDay(hour: 21, minute: 30);
  bool _blockAll = false;

  // Page colors: pastel screens use dark ink, dark screens use white.
  static const _bgs = [
    AppColors.bg,
    AppColors.bg,
    AppColors.bg,
    AppColors.bg,
    AppColors.bg,
    AppColors.bg,
    AppColors.bg,
  ];

  bool get _light => true;
  Color get _fg => _light ? AppColors.ink : Colors.white;

  void _next() {
    if (_i < _count - 1) {
      setState(() => _i++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final s = context.read<AppState>();
    if (_blockAll) {
      final apps = await BlockerService.installedApps();
      await s.setAll(apps.map((a) => a.packageName).toList());
    }
    await s.finishOnboarding(
      goalList: _goals.toList(),
      morning: _morning.hour * 60 + _morning.minute,
      night: _night.hour * 60 + _night.minute,
    );
    await s.rescheduleReminders();
  }

  Future<void> _pick(bool morning) async {
    final t = await showTimePicker(context: context, initialTime: morning ? _morning : _night);
    if (t != null) setState(() => morning ? _morning = t : _night = t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _bgs[_i],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              children: [
                SegBar(
                  count: _count,
                  index: _i,
                  active: _fg,
                  idle: _fg.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _i == 0
                      ? const SizedBox(height: 40)
                      : IconButton(
                          icon: Icon(Icons.arrow_back, color: _fg),
                          onPressed: () => setState(() => _i--),
                        ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(_i),
                      child: LayoutBuilder(
                        builder: (context, bc) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: bc.maxHeight),
                            child: _page(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _button(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button() {
    final labels = [
      'Begin my journey 🙏',
      'Continue',
      'That is what I need 💛',
      'Build my daily routine',
      'Continue',
      _blockAll ? 'Set up my focus 🔒' : 'Continue',
      'Continue to my plan',
    ];
    final enabled = !(_i == 1 && _habit == null) && !(_i == 4 && _goals.isEmpty);
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _light ? AppColors.ink : Colors.white,
        foregroundColor: _light ? Colors.white : AppColors.ink,
      ),
      onPressed: enabled ? _next : null,
      child: Text(labels[_i]),
    );
  }

  Widget _title(String t) => Text(t,
      textAlign: TextAlign.center, style: h(30, color: _fg));
  Widget _sub(String t) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(t,
            textAlign: TextAlign.center,
            style: h(16, color: _fg.withValues(alpha: 0.75), w: FontWeight.w500)),
      );

  Widget _page() {
    switch (_i) {
      case 0:
        return _hook();
      case 1:
        return _habitPage();
      case 2:
        return _solution();
      case 3:
        return _rhythm();
      case 4:
        return _focus();
      case 5:
        return _distractions();
      default:
        return _permissions();
    }
  }

  // ---- permissions ----
  bool _notifOk = false;
  bool _a11yOk = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPerms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone settings: look again.
    if (state == AppLifecycleState.resumed) _checkPerms();
  }

  Future<void> _checkPerms() async {
    final n = await NotificationService.areEnabled();
    final a = await BlockerService.hasPermission();
    if (mounted) setState(() {
          _notifOk = n;
          _a11yOk = a;
        });
  }

  Future<void> _askNotifications() async {
    await NotificationService.askPermission();
    await _checkPerms();
  }

  Widget _permCard({
    required Color color,
    required String emoji,
    required String title,
    required String why,
    required bool ok,
    required String action,
    required VoidCallback onTap,
  }) =>
      PastelCard(
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: h(20, color: AppColors.ink))),
              if (ok) const Icon(Icons.check_circle, color: AppColors.ink),
            ]),
            const SizedBox(height: 8),
            Text(why, style: h(14, color: AppColors.ink, w: FontWeight.w500).copyWith(height: 1.35)),
            const SizedBox(height: 12),
            if (ok)
              Text('Allowed ✓', style: h(15, color: AppColors.ink, w: FontWeight.w800))
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: onTap,
                child: Text(action),
              ),
          ],
        ),
      );

  Widget _permissions() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Two quick permissions 🔐', style: h(28, color: _fg)),
          const SizedBox(height: 6),
          Text('So Prayer Lock can do its job. You stay in control and can change them any time in Profile.',
              style: h(15, color: _fg.withValues(alpha: 0.7), w: FontWeight.w500)),
          const SizedBox(height: 16),
          _permCard(
            color: AppColors.blue,
            emoji: '🔔',
            title: 'Notifications',
            why:
                'Why: to remind you at your morning and night prayer times. Your prayers and feelings are never shown in a notification.',
            ok: _notifOk,
            action: 'Allow notifications',
            onTap: _askNotifications,
          ),
          const SizedBox(height: 12),
          if (defaultTargetPlatform == TargetPlatform.android)
            _permCard(
              color: AppColors.mint,
              emoji: '📵',
              title: 'App blocking',
              why:
                  'Why: to notice when you open an app YOU chose to lock, so we can show your prayer first. Android asks you to turn on Prayer Lock in Accessibility. We never read your screen, messages or passwords, and we share nothing.',
              ok: _a11yOk,
              action: 'Open Accessibility settings',
              onTap: BlockerService.requestPermission,
            )
          else
            _permCard(
              color: AppColors.mint,
              emoji: '📵',
              title: 'Screen Time access',
              why:
                  'Why: to cover the apps YOU choose with a "Pray first" screen. Apple keeps your app choices private on your phone. We never see which apps you pick, and we share nothing.',
              ok: _a11yOk,
              action: 'Allow Screen Time',
              onTap: () async {
                await BlockerService.requestPermission();
                await _checkPerms();
              },
            ),
          const SizedBox(height: 12),
          Text('Not now? You can still continue. App blocking and reminders just stay off until you allow them.',
              style: h(12, color: _fg.withValues(alpha: 0.6), w: FontWeight.w500)),
        ],
      );

  // 1. hook
  Widget _hook() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MoodFace(t: 1, size: 280),
          const SizedBox(height: 28),
          _title('What if you felt closer to Jesus every day? ✨'),
          _sub('Start your mornings with Him, not with notifications. End your nights in prayer, not endless scrolling.'),
        ],
      );

  // 2. habit question
  Widget _habitPage() {
    final options = [
      ('📱', 'Often', 'My phone wins most days', AppColors.blue),
      ('😅', 'Sometimes', 'I get distracted and forget', AppColors.yellow),
      ('🌿', 'Rarely', 'I want to feel close to Him again', AppColors.mint),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Does your phone get your attention before Jesus does?',
            style: h(30, color: _fg)),
        const SizedBox(height: 8),
        Text('No judgment here. Just be honest 🤍',
            style: h(16, color: _fg.withValues(alpha: 0.7), w: FontWeight.w500)),
        const SizedBox(height: 28),
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PastelCard(
              color: o.$4,
              onTap: () => setState(() => _habit = o.$2),
              child: Row(
                children: [
                  Text(o.$1, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.$2, style: h(22, color: AppColors.ink)),
                        Text(o.$3, style: h(14, color: AppColors.ink, w: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _habit == o.$2
                      ? const Icon(Icons.check_circle, color: AppColors.ink)
                      : const ArrowDot(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 3. solution
  Widget _solution() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Pic('lock', size: 84),
              Icon(Icons.arrow_forward_rounded, color: _fg),
              const Pic('pray', size: 84),
              Icon(Icons.arrow_forward_rounded, color: _fg),
              const Pic('unlock', size: 84),
            ],
          ),
          const SizedBox(height: 32),
          _title('Before you scroll, take a moment to pray 🙏'),
          _sub('Pick the apps that take your time. When you open one, Prayer Lock opens first. Pray, then continue 💛'),
        ],
      );

  // 4. daily rhythm + times
  Widget _rhythm() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Begin with prayer. End with peace. 🌅🌙', style: h(30, color: _fg)),
          const SizedBox(height: 8),
          Text('Two moments with Jesus every day. Tap to choose your time.',
              style: h(16, color: _fg.withValues(alpha: 0.7), w: FontWeight.w500)),
          const SizedBox(height: 24),
          PastelCard(
            color: AppColors.yellow,
            onTap: () => _pick(true),
            child: Row(children: [
              const Pic('sun', size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Morning with Jesus', style: h(20, color: AppColors.ink)),
                  Text('Gratitude, Scripture, guidance',
                      style: h(14, color: AppColors.ink, w: FontWeight.w500)),
                ]),
              ),
              Text(_morning.format(context), style: h(18, color: AppColors.ink)),
            ]),
          ),
          const SizedBox(height: 12),
          PastelCard(
            color: AppColors.blue,
            onTap: () => _pick(false),
            child: Row(children: [
              const Pic('moon', size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Rest with Jesus', style: h(20, color: AppColors.ink)),
                  Text('Release worries, give thanks',
                      style: h(14, color: AppColors.ink, w: FontWeight.w500)),
                ]),
              ),
              Text(_night.format(context), style: h(18, color: AppColors.ink)),
            ]),
          ),
          const SizedBox(height: 20),
          Text('We will remind you at these times with a gentle message 🔔',
              style: h(14, color: _fg.withValues(alpha: 0.6), w: FontWeight.w500)),
        ],
      );

  // 5. focus + progress
  Widget _focus() {
    final goals = [
      ('🔁', 'Praying every day'),
      ('🕊️', 'Peace of mind'),
      ('💛', 'Gratitude'),
      ('🧭', 'Guidance'),
      ('✝️', 'A closer walk with God'),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: AnimatedFire(size: 72)),
          const SizedBox(height: 8),
          Text('Small prayers. A stronger daily habit.', style: h(28, color: _fg)),
          const SizedBox(height: 6),
          Text('What do you want most? Choose all that fit.',
              style: h(16, color: _fg.withValues(alpha: 0.7), w: FontWeight.w500)),
          const SizedBox(height: 18),
          for (final g in goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PastelCard(
                color: _goals.contains(g.$2) ? AppColors.ink : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                onTap: () => setState(() =>
                    _goals.contains(g.$2) ? _goals.remove(g.$2) : _goals.add(g.$2)),
                child: Row(children: [
                  Text(g.$1, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(g.$2,
                        style: h(18,
                            color: _goals.contains(g.$2) ? Colors.white : AppColors.ink)),
                  ),
                  if (_goals.contains(g.$2))
                    const Icon(Icons.check_circle, color: AppColors.mint),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // 6. distractions
  Widget _distractions() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Pic('nav_locked', size: 110)),
          const SizedBox(height: 16),
          Text('Give Jesus the attention your phone keeps taking 📵',
              style: h(28, color: _fg)),
          const SizedBox(height: 10),
          Text(
              defaultTargetPlatform == TargetPlatform.iOS
                  ? 'Prayer Lock can pause your distracting apps until you pray. You pick the apps in the Locked apps tab, using Apple\'s own app picker.'
                  : 'Prayer Lock can pause your distracting apps until you pray. You can pick the exact apps later in the Locked apps tab. On Android, you will turn on one phone permission for this.',
              style: h(15, color: _fg.withValues(alpha: 0.7), w: FontWeight.w500)),
          const SizedBox(height: 24),
          if (defaultTargetPlatform != TargetPlatform.iOS)
          PastelCard(
            color: _blockAll ? AppColors.mint : AppColors.card,
            onTap: () => setState(() => _blockAll = true),
            child: Row(children: [
              const Text('🔒', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Block everything for now',
                    style: h(18, color: AppColors.ink)),
              ),
              if (_blockAll) const Icon(Icons.check_circle, color: AppColors.ink),
            ]),
          ),
          if (defaultTargetPlatform != TargetPlatform.iOS) const SizedBox(height: 12),
          PastelCard(
            color: !_blockAll || defaultTargetPlatform == TargetPlatform.iOS ? AppColors.yellow : AppColors.card,
            onTap: () => setState(() => _blockAll = false),
            child: Row(children: [
              const Text('⏳', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text("I'll do this later",
                    style: h(18, color: AppColors.ink)),
              ),
              if (!_blockAll) const Icon(Icons.check_circle, color: AppColors.ink),
            ]),
          ),
        ],
      );
}
