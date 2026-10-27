import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'girl_anim.dart';

/// The praying girl, alive, while a prayer is being written: a 6-frame
/// flip-book (assets/img/girl_pray_1..6.png), a gentle float, a breathing
/// glow and twinkling sparkles.
class PrayingLoader extends StatefulWidget {
  final String text;
  const PrayingLoader({super.key, this.text = 'Writing your prayer…'});
  @override
  State<PrayingLoader> createState() => _PrayingLoaderState();
}

class _PrayingLoaderState extends State<PrayingLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _t =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final a = _t.value * 2 * math.pi;
            final bob = math.sin(a) * 5;
            final glow = 0.55 + 0.25 * math.sin(a);
            return SizedBox(
              width: 260,
              height: 290,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFFFE27A).withValues(alpha: glow),
                      const Color(0xFFFFE27A).withValues(alpha: 0),
                    ]),
                  ),
                ),
                for (var i = 0; i < 5; i++) _sparkle(i, a),
                Transform.translate(
                  offset: Offset(0, bob),
                  child: const GirlAnim(kind: 'pray', size: 190),
                ),
              ]),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(widget.text, style: h(16, color: AppColors.soft, w: FontWeight.w600)),
      ],
    );
  }

  Widget _sparkle(int i, double a) {
    const spots = [Offset(-100, -80), Offset(105, -60), Offset(-85, 40), Offset(98, 55), Offset(10, -115)];
    final o = ((math.sin(a + i * 1.3) + 1) / 2).clamp(0.0, 1.0);
    return Transform.translate(
      offset: spots[i],
      child: Opacity(
        opacity: o,
        child: Transform.scale(
          scale: 0.6 + 0.6 * o,
          child: const Text('✦', style: TextStyle(fontSize: 18, color: Color(0xFFFFC93C))),
        ),
      ),
    );
  }
}
