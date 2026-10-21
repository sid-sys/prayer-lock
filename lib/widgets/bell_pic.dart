import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A friendly orange bell with a face. Drawn in code, so it needs no image file.
/// Used on the screens that ask for notification permission.
/// With [ring] true it swings gently.
class BellPic extends StatefulWidget {
  final double size;
  final bool ring;
  const BellPic({super.key, this.size = 220, this.ring = true});
  @override
  State<BellPic> createState() => _BellPicState();
}

class _BellPicState extends State<BellPic> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.ring) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // Swing for the first part of each cycle, then rest.
          final t = _c.value;
          final swing = t < 0.5 ? math.sin(t / 0.5 * math.pi * 4) * (1 - t / 0.5) * 0.18 : 0.0;
          return Transform.rotate(
            angle: swing,
            alignment: Alignment.topCenter,
            child: CustomPaint(painter: _BellPainter(), size: Size.square(widget.size)),
          );
        },
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final body = Paint()..color = const Color(0xFFFFB866);
    final shade = Paint()..color = const Color(0xFFEFA55E);
    final light = Paint()..color = const Color(0xFFFFD9A8);
    final ink = Paint()..color = const Color(0xFF3B2A22);

    // top knob
    canvas.drawCircle(Offset(w * 0.5, w * 0.12), w * 0.055, shade);

    // bell body
    final bell = Path()
      ..moveTo(w * 0.17, w * 0.74)
      ..cubicTo(w * 0.24, w * 0.62, w * 0.22, w * 0.50, w * 0.25, w * 0.40)
      ..cubicTo(w * 0.29, w * 0.22, w * 0.40, w * 0.15, w * 0.50, w * 0.15)
      ..cubicTo(w * 0.60, w * 0.15, w * 0.71, w * 0.22, w * 0.75, w * 0.40)
      ..cubicTo(w * 0.78, w * 0.50, w * 0.76, w * 0.62, w * 0.83, w * 0.74)
      ..close();
    canvas.drawPath(bell, body);

    // right side shade
    final side = Path()
      ..moveTo(w * 0.62, w * 0.17)
      ..cubicTo(w * 0.71, w * 0.22, w * 0.75, w * 0.30, w * 0.77, w * 0.42)
      ..cubicTo(w * 0.79, w * 0.52, w * 0.77, w * 0.63, w * 0.83, w * 0.74)
      ..lineTo(w * 0.70, w * 0.74)
      ..cubicTo(w * 0.72, w * 0.60, w * 0.70, w * 0.40, w * 0.62, w * 0.17)
      ..close();
    canvas.drawPath(side, shade);

    // rim
    final rim = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, w * 0.71, w * 0.80, w * 0.095), Radius.circular(w * 0.05));
    canvas.drawRRect(rim, body);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, w * 0.735, w * 0.12, w * 0.03), Radius.circular(w * 0.02)),
        light);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.29, w * 0.735, w * 0.03, w * 0.03), Radius.circular(w * 0.015)),
        light);

    // clapper
    canvas.drawCircle(Offset(w * 0.5, w * 0.85), w * 0.075, shade);

    // shine
    final shine = Path()
      ..moveTo(w * 0.33, w * 0.36)
      ..quadraticBezierTo(w * 0.34, w * 0.26, w * 0.43, w * 0.22)
      ..quadraticBezierTo(w * 0.37, w * 0.28, w * 0.37, w * 0.38)
      ..close();
    canvas.drawPath(shine, light);

    // face
    canvas.drawCircle(Offset(w * 0.42, w * 0.55), w * 0.032, ink);
    canvas.drawCircle(Offset(w * 0.58, w * 0.55), w * 0.032, ink);
    canvas.drawCircle(Offset(w * 0.4125, w * 0.543), w * 0.011, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.5725, w * 0.543), w * 0.011, Paint()..color = Colors.white);
    final smile = Path()
      ..moveTo(w * 0.465, w * 0.60)
      ..quadraticBezierTo(w * 0.50, w * 0.625, w * 0.535, w * 0.60);
    canvas.drawPath(
        smile,
        Paint()
          ..color = const Color(0xFF3B2A22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.014
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
