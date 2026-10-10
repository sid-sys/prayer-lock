import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated fire emoji. It flickers: grows, shrinks, tilts and glows.
class AnimatedFire extends StatefulWidget {
  final double size;
  const AnimatedFire({super.key, this.size = 96});
  @override
  State<AnimatedFire> createState() => _AnimatedFireState();
}

class _AnimatedFireState extends State<AnimatedFire> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

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
        final t = _c.value * 2 * math.pi;
        // Two sine waves with different speed make it look alive.
        final flick = math.sin(t) * 0.5 + math.sin(t * 3) * 0.5;
        final scaleY = 1.0 + 0.10 * flick;
        final scaleX = 1.0 - 0.05 * flick;
        final tilt = 0.06 * math.sin(t * 2);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 1.1,
              height: widget.size * 1.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A3D).withValues(alpha: 0.35 + 0.15 * flick),
                    blurRadius: 40 + 12 * flick,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..rotateZ(tilt)
                ..scale(scaleX, scaleY),
              child: Text('🔥', style: TextStyle(fontSize: widget.size, height: 1.1)),
            ),
          ],
        );
      },
    );
  }
}
