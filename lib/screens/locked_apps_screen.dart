import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import '../services/blocker_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class LockedAppsScreen extends StatefulWidget {
  const LockedAppsScreen({super.key});
  @override
  State<LockedAppsScreen> createState() => _LockedAppsScreenState();
}

class _LockedAppsScreenState extends State<LockedAppsScreen> {
  List<AppInfo> _all = [];
  bool _loading = true;
  String _q = '';

  // Two lists drive the screen. Items slide from one list to the other.
  List<AppInfo> _locked = [];
  List<AppInfo> _unlocked = [];
  GlobalKey<SliverAnimatedListState> _lk = GlobalKey();
  GlobalKey<SliverAnimatedListState> _uk = GlobalKey();

  /// Apps whose switch is flipping right now (before they slide across).
  final Set<String> _flipping = {};

  @override
  void initState() {
    super.initState();
    final ready = BlockerService.loaded;
    if (ready != null) {
      // List is already loaded: show it on the very first frame.
      _all = ready;
      _loading = false;
      _fill();
    } else {
      BlockerService.installedApps().then((a) {
        if (!mounted) return;
        _all = a;
        _loading = false;
        _rebuild();
      });
    }
  }

  void _fill() {
    final s = context.read<AppState>();
    final q = _q.toLowerCase();
    final f = _all.where((a) => a.name.toLowerCase().contains(q)).toList();
    _locked = f.where((a) => s.lockedApps.contains(a.packageName)).toList();
    _unlocked = f.where((a) => !s.lockedApps.contains(a.packageName)).toList();
    _lk = GlobalKey();
    _uk = GlobalKey();
  }

  /// Build both lists again from the saved state (search, bulk change, load).
  void _rebuild() => setState(_fill);

  Future<void> _toggle(AppInfo a) async {
    if (_flipping.contains(a.packageName)) return;
    final s = context.read<AppState>();
    final wasLocked = _locked.contains(a);

    // 1. Save right away and flip the switch where the app is now.
    s.toggleApp(a.packageName);
    setState(() => _flipping.add(a.packageName));

    // 2. Let the switch animate, then slide the app to the other section.
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    final from = wasLocked ? _locked : _unlocked;
    final to = wasLocked ? _unlocked : _locked;
    final fromKey = wasLocked ? _lk : _uk;
    final toKey = wasLocked ? _uk : _lk;

    final i = from.indexOf(a);
    if (i >= 0) {
      from.removeAt(i);
      fromKey.currentState?.removeItem(
        i,
        (context, anim) => _slide(a, !wasLocked, anim, leaving: true),
        duration: const Duration(milliseconds: 450),
      );

      // A newly locked app goes to the top so you see it arrive.
      var j = 0;
      if (wasLocked) {
        j = to.indexWhere((x) => x.name.toLowerCase().compareTo(a.name.toLowerCase()) > 0);
        if (j < 0) j = to.length;
      }
      to.insert(j, a);
      toKey.currentState?.insertItem(j, duration: const Duration(milliseconds: 550));
    }
    setState(() => _flipping.remove(a.packageName));
  }

  Widget _slide(AppInfo a, bool locked, Animation<double> anim, {bool leaving = false}) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, leaving ? (locked ? 0.8 : -0.8) : (locked ? -0.8 : 0.8)),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: leaving
              ? Tween<double>(begin: 0.88, end: 1).animate(curved)
              : Tween<double>(begin: 0.8, end: 1).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: curved, child: _tile(a, locked)),
        ),
      ),
    );
  }

  Widget _tile(AppInfo a, bool locked) {
    // While flipping, show the new state in the old place.
    final shown = _flipping.contains(a.packageName) ? !locked : locked;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: AnimatedScale(
        scale: _flipping.contains(a.packageName) ? 1.07 : 1.0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: shown ? AppColors.mint : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _flipping.contains(a.packageName)
              ? [
                  BoxShadow(
                    color: (shown ? AppColors.mint : AppColors.soft).withValues(alpha: 0.55),
                    blurRadius: 22,
                    spreadRadius: 2,
                  )
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _toggle(a),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  a.icon == null
                      ? const Icon(Icons.apps, size: 40)
                      : Image.memory(a.icon!, width: 40, height: 40, gaplessPlayback: true),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Text(a.name,
                          style: h(16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  SmoothSwitch(value: shown),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _header(String text, int n, String emoji) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
          child: Row(children: [
            Text('$emoji  $text', style: h(18)),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (c, a) => ScaleTransition(
                  scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
              child: Container(
                key: ValueKey(n),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.ink, borderRadius: BorderRadius.circular(12)),
                child: Text('$n', style: h(13, color: Colors.white)),
              ),
            ),
          ]),
        ),
      );

  Widget _empty(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
          child: Text(text, style: h(14, color: AppColors.soft, w: FontWeight.w500)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Locked apps 🔒', style: h(26)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) {
                _q = v;
                _rebuild();
              },
              decoration: InputDecoration(
                hintText: 'Search apps',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                TextButton(
                  onPressed: _all.isEmpty
                      ? null
                      : () async {
                          await s.setAll(_all.map((a) => a.packageName).toList());
                          _rebuild();
                        },
                  child: const Text('Block everything'),
                ),
                TextButton(
                  onPressed: () async {
                    await s.setAll([]);
                    _rebuild();
                  },
                  child: const Text('Unlock all'),
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: _Skeleton())
        else if (_all.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No apps found. The app list works on Android phones.',
                    textAlign: TextAlign.center, style: h(15, color: AppColors.soft)),
              ),
            ),
          )
        else ...[
          _header('Locked', _locked.length, '🔒'),
          if (_locked.isEmpty) _empty('Tap an app below to lock it.'),
          SliverAnimatedList(
            key: _lk,
            initialItemCount: _locked.length,
            itemBuilder: (context, i, anim) =>
                i < _locked.length ? _slide(_locked[i], true, anim) : const SizedBox(),
          ),
          _header('Unlocked', _unlocked.length, '🔓'),
          SliverAnimatedList(
            key: _uk,
            initialItemCount: _unlocked.length,
            itemBuilder: (context, i, anim) =>
                i < _unlocked.length ? _slide(_unlocked[i], false, anim) : const SizedBox(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }
}

/// Grey pulsing rows shown while the app list loads.
class _Skeleton extends StatefulWidget {
  const _Skeleton();
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final tone = Color.lerp(const Color(0xFFFFE8D2), const Color(0xFFFFF8F0), _c.value)!;
        Widget bar(double w, double hgt) => Container(
              width: w,
              height: hgt,
              decoration: BoxDecoration(
                  color: const Color(0xFFEBCDB0).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8)),
            );
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(110, 18),
              const SizedBox(height: 12),
              for (var i = 0; i < 8; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration:
                      BoxDecoration(color: tone, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEBCDB0).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(width: 14),
                    bar(120.0 + (i % 3) * 30, 14),
                    const Spacer(),
                    Container(
                      width: 52,
                      height: 30,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEBCDB0).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

