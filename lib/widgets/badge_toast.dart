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
            top: _visible ? top + 10 : -190,
            left: 14,
            right: 14,
            child: GestureDetector(
              onTap: _hide,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < 0) _hide();
              },
              child: Material(
                color: Colors.transparent,
                child: _card(_badge!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(PrayerBadge b) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.7), width: 2),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Pic(b.image, size: 70),
                const Positioned(right: -6, top: -6, child: Text('✨', style: TextStyle(fontSize: 18))),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏅 BADGE UNLOCKED',
                    style: h(11, color: AppColors.yellow, w: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(b.title, style: h(19, color: Colors.white)),
                const SizedBox(height: 2),
                Text(b.quip,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: h(13, color: Colors.white70, w: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
