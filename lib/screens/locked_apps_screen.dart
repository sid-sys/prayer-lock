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

  @override
  void initState() {
    super.initState();
    BlockerService.installedApps().then((a) {
      if (!mounted) return;
      _all = a;
      _loading = false;
      _rebuild();
    });
  }

  /// Build both lists again from the saved state (search, bulk change, load).
  void _rebuild() {
    final s = context.read<AppState>();
    final q = _q.toLowerCase();
    final f = _all.where((a) => a.name.toLowerCase().contains(q)).toList();
    setState(() {
      _locked = f.where((a) => s.lockedApps.contains(a.packageName)).toList();
      _unlocked = f.where((a) => !s.lockedApps.contains(a.packageName)).toList();
      _lk = GlobalKey();
      _uk = GlobalKey();
    });
  }

  void _toggle(AppInfo a) {
    final s = context.read<AppState>();
    final wasLocked = _locked.contains(a);
    final from = wasLocked ? _locked : _unlocked;
    final to = wasLocked ? _unlocked : _locked;
    final fromKey = wasLocked ? _lk : _uk;
    final toKey = wasLocked ? _uk : _lk;

    final i = from.indexOf(a);
    if (i < 0) return;
    from.removeAt(i);
    fromKey.currentState?.removeItem(
      i,
      (context, anim) => _slide(a, wasLocked, anim, leaving: true),
      duration: const Duration(milliseconds: 280),
    );

    // New locked app goes to the top so you can see it arrive.
    var j = 0;
    if (!wasLocked) {
      j = 0;
    } else {
      j = to.indexWhere((x) => x.name.toLowerCase().compareTo(a.name.toLowerCase()) > 0);
      if (j < 0) j = to.length;
    }
    to.insert(j, a);
    toKey.currentState?.insertItem(j, duration: const Duration(milliseconds: 380));

    s.toggleApp(a.packageName); // saved in the background
    setState(() {});
  }

  Widget _slide(AppInfo a, bool locked, Animation<double> anim, {bool leaving = false}) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, leaving ? -0.4 : 0.6),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: _tile(a, locked)),
      ),
    );
  }

  Widget _tile(AppInfo a, bool locked) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Material(
        color: locked ? AppColors.mint : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggle(a),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                a.icon == null
                    ? const Icon(Icons.apps, size: 40)
                    : Image.memory(a.icon!, width: 40, height: 40),
                const SizedBox(width: 14),
                Expanded(child: Text(a.name, style: h(16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Switch(value: locked, onChanged: (_) => _toggle(a)),
              ],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(12)),
              child: Text('$n', style: h(13, color: Colors.white)),
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
          const SliverFillRemaining(
              hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
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
