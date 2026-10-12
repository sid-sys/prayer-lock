import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/blocker_service.dart';
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
    if (!mounted) return;
    setState(() {
      _allowed = ok;
      _counts = c;
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
    await context.read<AppState>().setIosChosen(total);
    if (!mounted) return;
    setState(() {
      _counts = c;
      _busy = false;
    });
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
        const SizedBox(height: 16),
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
