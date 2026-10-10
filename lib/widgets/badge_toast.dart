import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Wraps the whole app. When a new badge is earned, a card slides down from
/// the top on any screen: picture, name and a playful line.
class BadgeToaster extends StatefulWidget {
  final Widget child;
  const BadgeToaster({super.key, required this.child});
  @override
  State<BadgeToaster> createState() => _BadgeToasterState();
}

class _BadgeToasterState extends State<BadgeToaster> {
  AppState? _state;
  PrayerBadge? _badge;
  bool _visible = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.read<AppState>();
    if (_state != s) {
      _state?.removeListener(_check);
      _state = s..addListener(_check);
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_busy || _state == null || !_state!.hasBadgeToast) return;
    _run(_state!.takeBadge()!);
  }

  Future<void> _run(PrayerBadge b) async {
    _busy = true;
    // let the screen that caused it settle first
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _badge = b;
      _visible = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _visible = true);
    await Future<void>.delayed(const Duration(milliseconds: 4200));
    await _hide();
  }

  Future<void> _hide() async {
    if (!mounted || _badge == null) return;
    setState(() => _visible = false);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _badge = null);
    _busy = false;
    _check(); // next one in the queue
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        widget.child,
        if (_badge != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 520),
            curve: _visible ? Curves.easeOutBack : Curves.easeInCubic,
            top: _visible ? top + 8 : -110,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _hide,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < 0) _hide();
              },
              child: Material(
                color: Colors.transparent,
                child: Center(child: _card(_badge!)),
              ),
            ),
          ),
      ],
    );
  }

  /// Small pill, about the size of a button.
  Widget _card(PrayerBadge b) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(8, 6, 18, 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.8), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Pic(b.image, size: 42),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏅 BADGE UNLOCKED',
                    style: h(9, color: AppColors.yellow, w: FontWeight.w800)),
                Text(b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: h(15, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
