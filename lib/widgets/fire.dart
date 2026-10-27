import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The 🔥 emoji, animated like a real flame.
/// The emoji is cut in 3 slices. The top slice sways most, so the tip
/// licks left and right while the base stays still. A glow breathes
/// behind it and sparks float up.
class AnimatedFire extends StatefulWidget {
  final double size;
  const AnimatedFire({super.key, this.size = 96});
  @override
  State<AnimatedFire> createState() => _AnimatedFireState();
}

class _AnimatedFireState extends State<AnimatedFire> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // loops cleanly because freq is a whole number
  double _s(int freq, [double phase = 0]) =>
      math.sin(2 * math.pi * (_c.value * freq + phase));

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final emoji = SizedBox(
      width: size * 1.1,
      height: size * 1.3,
      child: Image.asset('assets/img/ic_flame.png', fit: BoxFit.contain, filterQuality: FilterQuality.high),
    );
    return SizedBox(
      width: size * 1.7,
      height: size * 1.75,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final breathe = 1 + 0.06 * _s(5) + 0.03 * _s(9, 0.3);
          // sway angle (radians) for the tip, and half of it for the middle
          final tip = 0.20 * _s(3) + 0.08 * _s(7, 0.25);
          final mid = 0.09 * _s(3, 0.08) + 0.04 * _s(5, 0.5);
          final slice = size * 1.3 * 0.34;

          Widget part(double y, double heightFactor) => ClipRect(
                child: Align(
                  alignment: Alignment(0, y),
                  heightFactor: heightFactor,
                  child: emoji,
                ),
              );

          final bottom = part(1, 0.33);
          final middle = Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.skewX(mid),
            child: part(0, 0.34),
          );
          final top = Transform.translate(
            offset: Offset(-math.tan(mid) * slice, 0),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.skewX(tip),
              child: part(-1, 0.33),
            ),
          );

          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // glow
              Positioned(
                bottom: size * 0.05,
                child: Container(
                  width: size * 1.5 * breathe,
                  height: size * 1.5 * breathe,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFFF9A3D).withValues(alpha: 0.55),
                      const Color(0xFFFF9A3D).withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
              // soft blurred copy behind: makes the flame look hot
              Positioned(
                bottom: size * 0.10,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Opacity(
                    opacity: 0.55 + 0.2 * _s(6),
                    child: Transform.scale(
                      scale: 1.15 * breathe,
                      alignment: Alignment.bottomCenter,
                      child: emoji,
                    ),
                  ),
                ),
              ),
              // the flame itself, breathing taller and thinner
              Positioned(
                bottom: size * 0.10,
                child: Transform.scale(
                  scaleX: 1 - 0.04 * _s(5),
                  scaleY: breathe,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [top, middle, bottom],
                  ),
                ),
              ),
              // sparks
              for (var i = 0; i < 7; i++) _spark(i, size),
            ],
          );
        },
      ),
    );
  }

  Widget _spark(int i, double size) {
    final p = (_c.value * 2 + i / 7) % 1.0; // 0 bottom .. 1 top
    final x = math.sin((p * 3 + i) * 2.1) * size * 0.32;
    final y = size * 0.45 + p * size * 0.95;
    final a = (1 - p).clamp(0.0, 1.0);
    final r = (3.2 - p * 2.0) * (size / 110).clamp(0.6, 2.0);
    return Positioned(
      bottom: y,
      left: size * 0.85 + x - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFC94D).withValues(alpha: a),
        ),
      ),
    );
  }
}
