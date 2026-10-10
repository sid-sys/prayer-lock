import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Background color for a mood value 0..1 (0 = low, 1 = happy).
Color moodColor(double t) {
  const stops = [
    Color(0xFF9FA8FF), // blue, sad
    Color(0xFFB9A6FF), // violet
    Color(0xFFFFE27A), // yellow, calm
    Color(0xFFFFC999), // peach, happy
  ];
  final x = (t.clamp(0.0, 1.0)) * (stops.length - 1);
  final i = x.floor().clamp(0, stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], x - i)!;
}

String moodWord(double t) {
  if (t < 0.2) return 'Distant';
  if (t < 0.4) return 'Struggling';
  if (t < 0.6) return 'Okay';
  if (t < 0.8) return 'Close';
  return 'Very close';
}

/// Big cartoon eyes and mouth. The face changes smoothly as [t] changes.
class MoodFace extends StatelessWidget {
  final double t; // 0 sad .. 1 happy
  final double size;
  const MoodFace({super.key, required this.t, this.size = 280});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size * 0.62), painter: _FacePainter(t));
}

class _FacePainter extends CustomPainter {
  final double t;
  _FacePainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    const ink = Color(0xFF14141C);
    final w = s.width;
    final eyeW = w * 0.30;
    final eyeH = w * 0.34;
    final cy = s.height * 0.34;
    final lx = w * 0.27;
    final rx = w * 0.73;

    // Eye white: rounder when happy, a bit flatter when sad.
    final open = 0.78 + 0.22 * t;
    for (final cx in [lx, rx]) {
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: eyeW, height: eyeH * open);
      c.drawOval(rect, Paint()..color = Colors.white);
      c.drawOval(rect, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = ink);

      // Pupil looks up when happy, down when sad.
      final px = cx + (cx == lx ? 1 : -1) * eyeW * 0.04;
      final py = cy + eyeH * open * (0.16 - 0.30 * t);
      final pr = eyeW * 0.33;
      c.drawCircle(Offset(px, py), pr, Paint()..color = ink);
      c.drawCircle(Offset(px - pr * 0.35, py - pr * 0.35), pr * 0.28, Paint()..color = Colors.white);
      c.drawCircle(Offset(px + pr * 0.30, py + pr * 0.30), pr * 0.12, Paint()..color = Colors.white);

      // Sad lid drooping on the eye.
      final lid = ((0.5 - t) * 2).clamp(0.0, 1.0);
      if (lid > 0.03) {
        final k = lid;
        c.save();
        c.clipPath(Path()..addOval(rect));
        final drop = rect.height * 0.38 * k;
        final slant = (cx == lx ? -1 : 1) * rect.height * 0.12 * k;
        final p = Path()
          ..moveTo(rect.left - 4, rect.top - 4)
          ..lineTo(rect.right + 4, rect.top - 4)
          ..lineTo(rect.right + 4, rect.top + drop - slant)
          ..lineTo(rect.left - 4, rect.top + drop + slant)
          ..close();
        c.drawPath(p, Paint()..color = _lidColor);
        c.drawPath(p, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012
          ..color = ink);
        c.restore();
      }
    }

    // Cheeks appear when happy.
    final cheek = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
    if (cheek > 0) {
      final paint = Paint()..color = const Color(0xFFFF7F6E).withValues(alpha: 0.85 * cheek);
      c.drawOval(Rect.fromCenter(center: Offset(w * 0.16, s.height * 0.72), width: w * 0.16, height: w * 0.09), paint);
      c.drawOval(Rect.fromCenter(center: Offset(w * 0.84, s.height * 0.72), width: w * 0.16, height: w * 0.09), paint);
    }

    // Mouth: frown (t=0) -> flat -> smile (t=1).
    final mw = w * (0.12 + 0.12 * (t - 0.5).abs() * 2);
    final my = s.height * 0.80;
    final bend = (t - 0.5) * 2; // -1..1
    final path = Path()
      ..moveTo(w / 2 - mw, my)
      ..quadraticBezierTo(w / 2, my + bend * w * 0.11, w / 2 + mw, my);
    c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * 0.014
          ..color = ink);
  }

  Color get _lidColor => Color.lerp(const Color(0xFF9FA8FF), const Color(0xFFB9A6FF), 0.4)!;

  @override
  bool shouldRepaint(_FacePainter o) => o.t != t;
}

/// Slider with tick marks and a round thumb, like the reference.
class MoodSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color tick;
  const MoodSlider({super.key, required this.value, required this.onChanged, this.tick = const Color(0xFF14141C)});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      void set(double dx) => onChanged((dx / w).clamp(0.0, 1.0));
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => set(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
        child: SizedBox(
          height: 64,
          child: CustomPaint(painter: _SliderPainter(value, tick), size: Size(w, 64)),
        ),
      );
    });
  }
}

class _SliderPainter extends CustomPainter {
  final double v;
  final Color tick;
  _SliderPainter(this.v, this.tick);
  @override
  void paint(Canvas c, Size s) {
    const n = 24;
    final p = Paint()
      ..color = tick.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= n; i++) {
      final x = s.width * i / n;
      final near = math.max(0.0, 1 - ((x - s.width * v).abs() / 60));
      final hh = 6 + 8 * near;
      c.drawLine(Offset(x, s.height / 2 - hh), Offset(x, s.height / 2 + hh), p);
    }
    final cx = s.width * v;
    c.drawCircle(Offset(cx, s.height / 2), 17, Paint()..color = Colors.white);
    c.drawCircle(Offset(cx, s.height / 2), 17, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF14141C));
  }

  @override
  bool shouldRepaint(_SliderPainter o) => o.v != v;
}
