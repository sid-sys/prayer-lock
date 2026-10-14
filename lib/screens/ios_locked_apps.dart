import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/blocker_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Locked apps tab on iPhone.
/// Apple does not give apps a list of installed apps. Instead the person picks
/// apps in Apple's own picker, and Apple hides which ones they chose from us.
class IosLockedApps extends StatefulWidget {
  const IosLockedApps({super.key});
  @override
  State<IosLockedApps> createState() => _IosLockedAppsState();
}

class _IosLockedAppsState extends State<IosLockedApps> with WidgetsBindingObserver {
  bool _allowed = false;
  bool _notifOk = true;
  bool _busy = false;
  Map<String, int> _counts = {'apps': 0, 'categories': 0, 'websites': 0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final ok = await BlockerService.hasPermission();
    final c = await BlockerService.summary();
    final n = await NotificationService.areEnabled();
    if (!mounted) return;
    setState(() {
      _allowed = ok;
      _counts = c;
      _notifOk = n;
    });
  }

  Future<void> _allow() async {
    setState(() => _busy = true);
    await BlockerService.requestPermission();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    final c = await BlockerService.pickApps();
    if (!mounted) return;
    final total = c.values.fold<int>(0, (a, b) => a + b);
    final state = context.read<AppState>();
    await state.setIosChosen(total);
    // Make sure the lock is really on for the new choice.
    await state.relock();
    // "Pray now" on the lock screen works through a notification, so ask for it here too.
    if (total > 0 && !await NotificationService.areEnabled()) {
      await NotificationService.askPermission();
    }
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  String get _summary {
    final a = _counts['apps'] ?? 0;
    final c = _counts['categories'] ?? 0;
    final w = _counts['websites'] ?? 0;
    if (a + c + w == 0) return 'No apps chosen yet';
    final parts = <String>[
      if (a > 0) '$a ${a == 1 ? 'app' : 'apps'}',
      if (c > 0) '$c ${c == 1 ? 'category' : 'categories'}',
      if (w > 0) '$w ${w == 1 ? 'website' : 'websites'}',
    ];
    return '${parts.join(', ')} locked';
  }

  Widget _row(String label, bool ok, String good, String bad) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(ok ? '✅' : '⚠️', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: h(14, w: FontWeight.w600))),
          Text(ok ? good : bad,
              style: h(13, color: ok ? AppColors.soft : const Color(0xFFD84315), w: FontWeight.w700)),
        ]),
      );

  /// Shows what is on or off, so a problem is easy to see.
  Widget _statusCard(BuildContext context) {
    final s = context.watch<AppState>();
    final chosen = (_counts.values.fold<int>(0, (a, b) => a + b)) > 0;
    final open = s.isUnlocked;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status', style: h(16)),
          const SizedBox(height: 6),
          _row('Screen Time access', _allowed, 'Allowed', 'Not allowed'),
          _row('Apps chosen', chosen, '$_totalChosen', 'None'),
          _row('Notifications', _notifOk, 'On', 'Off: needed for "Pray now"'),
          _row('Lock', !open && s.blockingOn, 'On', open ? 'Open for now' : 'Switched off'),
          if (!_notifOk)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: () async {
                  await NotificationService.askPermission();
                  await _refresh();
                },
                child: const Text('Allow notifications'),
              ),
            ),
          if (open && chosen)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton(
                onPressed: () async {
                  await s.lockNow();
                  await _refresh();
                },
                child: const Text('Lock my apps now 🔒'),
              ),
            ),
          if (!open && s.blockingOn && chosen && _allowed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'Open one of your chosen apps. A "Pray first" screen should cover it. Tap "Pray now", then tap the notification.',
                  style: h(12, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.4)),
            ),
        ]),
      ),
    );
  }

  int get _totalChosen => _counts.values.fold<int>(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final chosen = (_counts.values.fold<int>(0, (a, b) => a + b)) > 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Locked apps 🔒', style: h(26)),
        const SizedBox(height: 16),
        PastelCard(
          color: chosen ? AppColors.mint : AppColors.pink,
          child: Row(children: [
            Pic(chosen ? 'lock' : 'unlock', size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_summary, style: h(19, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                    chosen
                        ? 'You will pray before you open them.'
                        : 'Pick the apps that take your time.',
                    style: h(14, color: AppColors.ink, w: FontWeight.w500)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _statusCard(context),
        const SizedBox(height: 12),
        if (!_allowed) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('1. Allow Screen Time', style: h(18)),
                const SizedBox(height: 6),
                Text(
                    'Apple needs your OK before an app can cover other apps. Apple keeps the apps you pick private. We never see which ones.',
                    style: h(14, color: AppColors.soft, w: FontWeight.w500)),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _busy ? null : _allow,
                  child: const Text('Allow Screen Time'),
                ),
              ]),
            ),
          ),
        ] else ...[
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.apps),
            label: Text(chosen ? 'Change my apps' : 'Choose apps to lock'),
          ),
          const SizedBox(height: 10),
          if (chosen)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.ink, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: _busy
                  ? null
                  : () async {
                      final state = context.read<AppState>();
                      await BlockerService.clearChoice();
                      await state.setIosChosen(0);
                      await _refresh();
                    },
              child: const Text('Unlock all apps'),
            ),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('How it works', style: h(17)),
              const SizedBox(height: 8),
              Text(
                  '1. You pick apps.\n2. When you open one, a "Pray first" screen covers it.\n3. Tap "Pray now". A notification appears. Tap it to open Prayer Lock.\n4. Pray. Your apps open for the time you choose, then lock again.',
                  style: h(14, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.5)),
            ]),
          ),
        ),
      ],
    );
  }
}
