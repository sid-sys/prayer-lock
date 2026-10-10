import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated flame. Three layers (red-orange, orange-yellow, bright core)
/// sway and breathe at different speeds, with a glow and rising sparks.
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.35,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _FirePainter(_c.value)),
      ),
    );
  }
}

class _FirePainter extends CustomPainter {
  final double v; // 0..1 loops every 6 seconds
  _FirePainter(this.v);

  // sine wave that loops cleanly: freq must be a whole number
  double _s(int freq, [double phase = 0]) => math.sin(2 * math.pi * (v * freq + phase));

  Path _flame(double cx, double baseY, double w, double h, double sway, double lean) {
    final tipX = cx + sway;
    final tipY = baseY - h;
    return Path()
      ..moveTo(cx, baseY)
      ..cubicTo(cx - w * 0.75, baseY - h * 0.10, cx - w * 0.55 + lean * 0.4,
          baseY - h * 0.58, tipX, tipY)
      ..cubicTo(cx + w * 0.30 + lean, baseY - h * 0.62, cx + w * 0.78,
          baseY - h * 0.12, cx, baseY)
      ..close();
  }

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final baseY = s.height * 0.94;
    final w = s.width * 0.52;
    final breathe = 1 + 0.05 * _s(6) + 0.03 * _s(11, 0.3);

    // glow
    final glowR = s.width * (0.55 + 0.04 * _s(6));
    c.drawCircle(
      Offset(cx, baseY - s.height * 0.32),
      glowR,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF9A3D).withValues(alpha: 0.55),
          const Color(0xFFFF9A3D).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(
            center: Offset(cx, baseY - s.height * 0.32), radius: glowR)),
    );

    // small side tongues
    final tl = _flame(cx - w * 0.52, baseY, w * 0.45, s.height * (0.50 + 0.05 * _s(7, 0.1)),
        -w * 0.10 + w * 0.07 * _s(5, 0.2), -w * 0.1);
    final tr = _flame(cx + w * 0.55, baseY, w * 0.40, s.height * (0.44 + 0.05 * _s(8, 0.6)),
        w * 0.10 + w * 0.07 * _s(6, 0.5), w * 0.1);
    final side = Paint()..color = const Color(0xFFFF5A1F);
    c.drawPath(tl, side);
    c.drawPath(tr, side);

    // outer flame
    final outerH = s.height * 0.86 * breathe;
    final outer = _flame(cx, baseY, w, outerH, w * 0.16 * _s(3) + w * 0.06 * _s(8, 0.4),
        w * 0.12 * _s(4, 0.25));
    c.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF8A1F), Color(0xFFFF4B14), Color(0xFFE02A0B)],
        ).createShader(Rect.fromLTWH(0, baseY - outerH, s.width, outerH)),
    );

    // middle flame
    final midH = outerH * 0.68 * (1 + 0.05 * _s(9, 0.2));
    final mid = _flame(cx, baseY - 2, w * 0.68, midH, w * 0.12 * _s(4, 0.1),
        w * 0.08 * _s(5, 0.6));
    c.drawPath(
      mid,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD43B), Color(0xFFFFA11F)],
        ).createShader(Rect.fromLTWH(0, baseY - midH, s.width, midH)),
    );

    // core
    final coreH = outerH * 0.38 * (1 + 0.08 * _s(10));
    final core = _flame(cx, baseY - 4, w * 0.36, coreH, w * 0.06 * _s(5, 0.3), 0);
    c.drawPath(core, Paint()..color = const Color(0xFFFFF4C2));

    // sparks
    for (var i = 0; i < 7; i++) {
      final p = (v * 2 + i / 7) % 1.0; // 0 bottom .. 1 top
      final x = cx + math.sin((p * 3 + i) * 2.1) * w * 0.55;
      final y = baseY - outerH * 0.45 - p * s.height * 0.5;
      final a = (1 - p).clamp(0.0, 1.0);
      c.drawCircle(
        Offset(x, y),
        (2.4 - p * 1.4) * (s.width / 150).clamp(0.6, 2.0),
        Paint()..color = const Color(0xFFFFC94D).withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_FirePainter o) => o.v != v;
}
