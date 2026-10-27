import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// The praying girl, alive, while a prayer is being written.
///
/// It plays her frames one after another like a flip-book (no fading between
/// them, which looks like a still picture), floats her gently up and down,
/// breathes a soft glow behind her and twinkles small sparkles around her.
///
/// Frames are assets/img/girl_pray_1.png ... girl_pray_N.png (N = frameCount).
/// The brand sheet has 5. To get a smoother loop add a 6th (or more) as
/// girl_pray_6.png and raise [frameCount]. The loop plays forward then back.
class PrayingLoader extends StatefulWidget {
  final String text;
  const PrayingLoader({super.key, this.text = 'Writing your prayer…'});

  /// Number of picture files. Raise this when you add girl_pray_6.png.
  static const frameCount = 5;

  @override
  State<PrayingLoader> createState() => _PrayingLoaderState();
}

class _PrayingLoaderState extends State<PrayingLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _t =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  Timer? _flip;
  int _step = 0;

  // forward then back: 0 1 2 3 4 3 2 1
  late final List<int> _seq = [
    for (var i = 0; i < PrayingLoader.frameCount; i++) i,
    for (var i = PrayingLoader.frameCount - 2; i >= 1; i--) i,
  ];

  @override
  void initState() {
    super.initState();
    _flip = Timer.periodic(const Duration(milliseconds: 170), (_) {
      if (mounted) setState(() => _step = (_step + 1) % _seq.length);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load all frames now so the first loop does not flicker.
    for (var i = 1; i <= PrayingLoader.frameCount; i++) {
      precacheImage(AssetImage('assets/img/girl_pray_$i.png'), context);
    }
  }

  @override
  void dispose() {
    _flip?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _seq[_step] + 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final a = _t.value * 2 * math.pi;
            final bob = math.sin(a) * 5; // float up and down
            final glow = 0.55 + 0.25 * math.sin(a); // soft breathing glow
            return SizedBox(
              width: 250,
              height: 270,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 210,
                  height: 210,
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
                  child: Image.asset(
                    'assets/img/girl_pray_$frame.png',
                    width: 170,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
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
    const spots = [
      Offset(-95, -70),
      Offset(100, -55),
      Offset(-80, 35),
      Offset(92, 50),
      Offset(10, -105),
    ];
    final phase = a + i * 1.3;
    final o = ((math.sin(phase) + 1) / 2).clamp(0.0, 1.0);
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
