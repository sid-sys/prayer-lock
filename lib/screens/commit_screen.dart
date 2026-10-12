import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Shown right before the paywall. Hold the fingerprint button: black spreads
/// from the button and flips every color on the screen (white <-> black).
class CommitScreen extends StatefulWidget {
  /// Freeze the hold at this value 0..1 (used by screenshot mode).
  final double? demoProgress;
  const CommitScreen({super.key, this.demoProgress});
  @override
  State<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends State<CommitScreen> with TickerProviderStateMixin {
  static const _holdMs = 2300;

  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _holdMs),
    reverseDuration: const Duration(milliseconds: 700),
  );

  /// Soft breathing ring around the button, so people know to press it.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat(reverse: true);

  int _lastTick = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.demoProgress != null) _hold.value = widget.demoProgress!;
    _hold.addListener(() {
      // a small tap feeling every quarter of the way
      final tick = (_hold.value * 8).floor();
      if (tick != _lastTick && _hold.status == AnimationStatus.forward) {
        HapticFeedback.selectionClick();
      }
      _lastTick = tick;
    });
    _hold.addStatusListener((st) async {
      if (st == AnimationStatus.completed && !_done) {
        _done = true;
        HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (mounted) context.read<AppState>().commit();
      }
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _down() {
    if (_done) return;
    HapticFeedback.lightImpact();
    _hold.forward();
  }

  void _up() {
    if (_done) return;
    _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final center = Offset(w / 2, h * 0.64);
      final maxR = math.sqrt(
          math.pow(math.max(center.dx, w - center.dx), 2) +
              math.pow(math.max(center.dy, h - center.dy), 2));

      return AnimatedBuilder(
        animation: Listenable.merge([_hold, _pulse]),
        builder: (context, _) {
          final t = Curves.easeInCubic.transform(_hold.value);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: t > 0.55 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  // 1. white screen, black content (this one takes the touch)
                  _layer(w, h, center, bg: Colors.white, fg: Colors.black, touch: true),
                  // 2. black screen, white content, shown only inside the growing circle
                  if (t > 0)
                    IgnorePointer(
                      child: ClipPath(
                        clipper: _CircleClipper(center, t * maxR),
                        child: _layer(w, h, center,
                            bg: Colors.black, fg: Colors.white, touch: false),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// The whole screen drawn once in the given colors.
  Widget _layer(double w, double h, Offset center,
      {required Color bg, required Color fg, required bool touch}) {
    const size = 150.0;
    final progress = _hold.value;
    final pulse = Curves.easeInOut.transform(_pulse.value);

    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
      child: Icon(Icons.fingerprint, size: 88, color: bg),
    );

    return Container(
      color: bg,
      width: w,
      height: h,
      child: Stack(
        children: [
          // Title and subtitle
          Positioned(
            left: 28,
            right: 28,
            top: h * 0.12,
            child: Column(
              children: [
                Text('🙏', style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 16),
                Text('I am ready to commit my devotion to Jesus',
                    textAlign: TextAlign.center, style: h2(32, fg)),
                const SizedBox(height: 14),
                Text('Hold the button to commit your devotion to Jesus',
                    textAlign: TextAlign.center,
                    style: h2(16, fg.withValues(alpha: 0.65), FontWeight.w500)),
              ],
            ),
          ),

          // Breathing ring (only when idle)
          Positioned(
            left: center.dx - (size / 2 + 22 + 10 * pulse),
            top: center.dy - (size / 2 + 22 + 10 * pulse),
            child: Opacity(
              opacity: progress > 0 ? 0 : 0.18 + 0.12 * (1 - pulse),
              child: Container(
                width: size + 44 + 20 * pulse,
                height: size + 44 + 20 * pulse,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, border: Border.all(color: fg, width: 3)),
              ),
            ),
          ),

          // Progress ring
          Positioned(
            left: center.dx - (size / 2 + 14),
            top: center.dy - (size / 2 + 14),
            child: SizedBox(
              width: size + 28,
              height: size + 28,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                backgroundColor: fg.withValues(alpha: 0.12),
                color: fg,
              ),
            ),
          ),

          // The button
          Positioned(
            left: center.dx - size / 2,
            top: center.dy - size / 2,
            child: touch
                ? Listener(
                    onPointerDown: (_) => _down(),
                    onPointerUp: (_) => _up(),
                    onPointerCancel: (_) => _up(),
                    child: Transform.scale(scale: 1 + 0.06 * progress, child: button),
                  )
                : Transform.scale(scale: 1 + 0.06 * progress, child: button),
          ),

          // Hint under the button
          Positioned(
            left: 28,
            right: 28,
            top: center.dy + size / 2 + 44,
            child: Text(
              _done
                  ? 'Amen 🙌'
                  : progress == 0
                      ? 'Press and hold'
                      : 'Keep holding…',
              textAlign: TextAlign.center,
              style: h2(18, fg.withValues(alpha: 0.7), FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle h2(double size, Color color, [FontWeight w = FontWeight.w800]) =>
      h(size, color: color, w: w);
}

class _CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  _CircleClipper(this.center, this.radius);

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper old) => old.radius != radius || old.center != center;
}
